/* SPDX-License-Identifier: (LGPL-2.1 OR BSD-2-Clause) */
/* Copyright (c) 2020 Facebook */
#ifndef __MARIADB_LATENCY_H
#define __MARIADB_LATENCY_H

#define TASK_QUERY_LEN	 52488
#define MAX_FILENAME_LEN 127

struct event {
	int tid;
	unsigned long long duration_ns;
	char query[TASK_QUERY_LEN];
	bool exit_query;
};

#endif /* __MARIADB_LATENCY_H */
