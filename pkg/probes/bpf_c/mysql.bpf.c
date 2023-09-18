// SPDX-License-Identifier: GPL-2.0 OR BSD-3-Clause
/* Copyright (c) 2020 Facebook */
#include "../../../builder/vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>
#include <bpf/bpf_core_read.h>

#define TASK_QUERY_LEN	 52488
#define MAX_FILENAME_LEN 127
#define COM_QUERY 0x03


char LICENSE[] SEC("license") = "Dual BSD/GPL";

struct event {
	unsigned long long duration_ns;
	char query[TASK_QUERY_LEN];
};


// static volatile char query_string[TASK_QUERY_LEN];
struct lookup {
	u64 ts;
	bool is_query;
	char query[TASK_QUERY_LEN];
};

struct COM_QUERY_DATA {
  const char *query;
  unsigned int length;
  struct PS_PARAM *parameters;
  unsigned long parameter_count;
};

union COM_DATA {
    struct COM_QUERY_DATA com_query;
};

static volatile struct lookup lookup_instance = {};
static volatile struct COM_QUERY_DATA com_query_data = {};
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

SEC("uprobe")
int BPF_KPROBE(uprobe_query, const char *str_a, const union COM_DATA *com_data, const int command)
{
	pid_t tid;

	/* remember time query was executed for this TID */
	tid = (u32)(bpf_get_current_pid_tgid());

	lookup_instance.ts = bpf_ktime_get_ns();
	
	if(command==COM_QUERY){
		lookup_instance.is_query = true;
		if(com_data!=NULL){
            bpf_probe_read((void *)&com_query_data, sizeof(com_query_data), &com_data->com_query);
            if(com_query_data.query!=NULL){
                bpf_probe_read_str((void *)&lookup_instance.query, sizeof(lookup_instance.query), com_query_data.query);
            }
        }
	}
	else{
		lookup_instance.query[0] = '\0';
		lookup_instance.is_query = false;
	}
	bpf_map_update_elem(&query, &tid, (const void *)&lookup_instance, BPF_ANY);
	return 0;
}

SEC("uretprobe")
int BPF_KRETPROBE(uretprobe_query)
{
	struct event *e;
	pid_t tid;
	u64 start_ts, duration_ns = 0;
	/* get PID and TID of exiting thread/process */
	tid = (u32)(bpf_get_current_pid_tgid());


	struct lookup *query_exit;
	query_exit = bpf_map_lookup_elem(&query, &tid);
	if(!query_exit) 
		return 0;
	
	if(query_exit->is_query==false)
		return 0;
	/* if we recorded start of the process, calculate lifetime duration */
	start_ts = query_exit->ts;
	duration_ns = bpf_ktime_get_ns() - start_ts;

	/* if process didn't live long enough, return early */
	if (min_duration_ns && duration_ns < min_duration_ns)
		return 0;
	/* reserve sample from BPF ringbuf */
	e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
	if (!e)
		return 0;

	e->duration_ns = duration_ns;

	bpf_probe_read_str(&e->query, sizeof(e->query), query_exit->query);
	bpf_map_delete_elem(&query, &tid);
	/* send data to user-space for post-processing */
	bpf_ringbuf_submit(e, 0);
	return 0;
}
