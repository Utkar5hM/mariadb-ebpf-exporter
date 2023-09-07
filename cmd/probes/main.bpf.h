/* SPDX-License-Identifier: (LGPL-2.1 OR BSD-2-Clause) */
/* Copyright (c) 2020 Facebook */
#ifndef __MAIN_BPF_H
#define __MAIN_BPF_H

#define TASK_QUERY_LEN	 52488
#define MAX_FILENAME_LEN 127

struct event {
	unsigned long long duration_ns;
	char query[TASK_QUERY_LEN];
};

#endif /* __MAIN_BPF_H */
