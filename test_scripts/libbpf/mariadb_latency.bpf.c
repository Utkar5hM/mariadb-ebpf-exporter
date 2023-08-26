// SPDX-License-Identifier: GPL-2.0 OR BSD-3-Clause
/* Copyright (c) 2020 Facebook */
#include <linux/bpf.h>
#include <linux/ptrace.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

char LICENSE[] SEC("license") = "Dual BSD/GPL";

SEC("uprobe//usr/bin/mariadbd:dispatch_command")
int BPF_KPROBE(uprobe_query, const char *str_a, const char *str_b)
{
    bpf_printk("uprobed_query ENTRY: a = %s, b = %s", str_a, str_b);
    return 0;
}


SEC("uretprobe//usr/bin/mariadbd:dispatch_command")
int BPF_KRETPROBE(uretprobe_query, int ret)
{
	bpf_printk("uprobed_query EXIT: return = %d", ret);
	return 0;
}
