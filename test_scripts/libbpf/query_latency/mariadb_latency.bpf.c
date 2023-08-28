// SPDX-License-Identifier: GPL-2.0 OR BSD-3-Clause
/* Copyright (c) 2020 Facebook */
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>
#include <bpf/bpf_core_read.h>
#include "mariadb_latency.h"

#define TASK_QUERY_LEN	 52488

char LICENSE[] SEC("license") = "Dual BSD/GPL";

// static volatile char query_string[TASK_QUERY_LEN];
struct lookup {
	char query[TASK_QUERY_LEN];
};


static volatile struct lookup lookup = {};

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, 4096);
	__type(key, pid_t);
	__type(value, u64);
} query_start SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, 4096);
	__type(key, pid_t);
	__type(value, struct lookup);
} query SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_RINGBUF);
	__uint(max_entries, 256 * 1024);
} rb SEC(".maps");

const volatile unsigned long long min_duration_ns = 0;

SEC("uprobe//usr/bin/mariadbd:_Z16dispatch_command19enum_server_commandP3THDPcjb")
int BPF_KPROBE(uprobe_query, const char *str_a, const char *str_b, const char *str_c)
{
	pid_t tid;
	u64 ts;

	/* remember time query was executed for this TID */
	tid = (u32)(bpf_get_current_pid_tgid());
	ts = bpf_ktime_get_ns();
	bpf_map_update_elem(&query_start, &tid, &ts, BPF_ANY);

	bpf_probe_read_user_str((void *)&lookup.query, sizeof(lookup.query), str_c);
	bpf_map_update_elem(&query, &tid, (const void *)&lookup, BPF_ANY);

	return 0;
}

SEC("uretprobe//usr/bin/mariadbd:_Z16dispatch_command19enum_server_commandP3THDPcjb")
int BPF_KRETPROBE(uretprobe_query)
{
	struct event *e;
	pid_t tid;
	u64 *start_ts, duration_ns = 0;
	/* get PID and TID of exiting thread/process */
	tid = (u32)(bpf_get_current_pid_tgid());

	/* if we recorded start of the process, calculate lifetime duration */
	start_ts = bpf_map_lookup_elem(&query_start, &tid);
	if (start_ts)
		duration_ns = bpf_ktime_get_ns() - *start_ts;
	else if (min_duration_ns)
		return 0;
	bpf_map_delete_elem(&query_start, &tid);

	/* if process didn't live long enough, return early */
	if (min_duration_ns && duration_ns < min_duration_ns)
		return 0;

	/* reserve sample from BPF ringbuf */
	e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
	if (!e)
		return 0;

	e->exit_query = true;
	e->duration_ns = duration_ns;
	e->tid = tid;

	struct lookup *query_exit;
	query_exit = bpf_map_lookup_elem(&query, &tid);
	bpf_probe_read_str(&e->query, sizeof(e->query), query_exit->query);
	bpf_map_delete_elem(&query, &tid);
	bpf_printk("Exit: query = %s", query_exit->query);
	/* send data to user-space for post-processing */
	bpf_ringbuf_submit(e, 0);
	return 0;
}
