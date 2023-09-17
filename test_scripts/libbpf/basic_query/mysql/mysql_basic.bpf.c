// SPDX-License-Identifier: GPL-2.0 OR BSD-3-Clause
/* Copyright (c) 2020 Facebook */
#include <linux/bpf.h>
#include <linux/ptrace.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>



#define COM_QUERY 0x03
char LICENSE[] SEC("license") = "Dual BSD/GPL";

struct COM_QUERY_DATA {
  const char *query;
  unsigned int length;
  struct PS_PARAM *parameters;
  unsigned long parameter_count;
};

union COM_DATA {
    struct COM_QUERY_DATA com_query;
};

SEC("uprobe//proc/3301/exe:_Z16dispatch_commandP3THDPK8COM_DATA19enum_server_command")
int BPF_KPROBE(uprobe_query, const char *str_a, const union COM_DATA *com_data, const int command)
{
    if(command==COM_QUERY){
        bpf_printk("ENTRY: query = %d", command);
        if(com_data!=NULL){
            struct COM_QUERY_DATA com_query_data;
            bpf_probe_read(&com_query_data, sizeof(com_query_data), &com_data->com_query);
            if(com_query_data.query!=NULL){
                char query[256];
                bpf_probe_read_str(&query, sizeof(query), com_query_data.query);
                bpf_printk("ENTRY: query = %s", query);
            }
        }
    }
    bpf_printk("ENTRY: query executed");
    return 0;
}


SEC("uretprobe//proc/3301/exe:_Z16dispatch_commandP3THDPK8COM_DATA19enum_server_command")
int BPF_KRETPROBE(uretprobe_query, int ret)
{
	bpf_printk("uprobed_query EXIT: return = %d", ret);
	return 0;
}
