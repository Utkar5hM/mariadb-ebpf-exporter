// SPDX-License-Identifier: GPL-2.0 OR BSD-3-Clause
/* Copyright (c) 2020 Facebook */
#include <linux/bpf.h>
#include <linux/ptrace.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

char LICENSE[] SEC("license") = "Dual BSD/GPL";

SEC("uprobe//usr/bin/mariadbd:_Z16dispatch_command19enum_server_commandP3THDPcjb")
int BPF_KPROBE(uprobe_query, const char *str_a, const char *str_b, const char *str_c)
{
    bpf_printk("ENTRY: query = %s", str_c);
    return 0;
}


SEC("uretprobe//usr/bin/mariadbd:_Z16dispatch_command19enum_server_commandP3THDPcjb")
int BPF_KRETPROBE(uretprobe_query, int ret)
{
	bpf_printk("uprobed_query EXIT: return = %d", ret);
	return 0;
}
