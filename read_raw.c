/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 *
 * Copyright (C) 2014 Jakub Kicinski <kubakici@wp.pl>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>

#define _BSD_SOURCE 1

#define ADDR_STAT_MAX 0x01FF
#define ADDR_REG_MIN  0xFF00
#define ADDR_REG_MAX  0xFFFF

#define NUM_REG_BYTES	28
#define ADDR_LEN	2

#define msg(fmt, ...) fprintf(stderr, fmt, ##__VA_ARGS__)

#if USE_COLORS
#define NORM "\e[0m"
#define BOLD "\e[1m"
#else
#define NORM ""
#define BOLD ""
#endif


/* Format in which device reports register dumps. */
struct reg_dump {
	unsigned long long __addr : 16;   /* Statistic addr, 0xFFFF for register dump. */
	unsigned long long pkt_len : 16;
	unsigned long long pkt_ival : 32;
	unsigned long long pkt_delay : 32;
	unsigned long long tx_frames : 36;
	unsigned long long rx_control : 36;
	unsigned long long rx_data : 36;
	unsigned long long ts_uflow : 36;
} __attribute__ ((packed));

struct statistic {
	unsigned long long __addr : 16;
	unsigned long long value : 40;
} __attribute__ ((packed));

static void print_start_line(int *last_record, const char *name)
{
	time_t t;
	struct tm *tm;
	char str_time[64];

	if (*last_record & 1) /* close record */
		msg("\n");
	*last_record = 0;

	t = time(NULL);
	tm = localtime(&t);

	if (!strftime(str_time, sizeof(str_time), "%T %F", tm)) {
		msg("Time-printing error!?\n");
		return;
	}

	msg("\n" BOLD "%s @%s" NORM "\n", name, str_time);
}

static int term_init(int fd)
{
	struct termios tty = { 0 };

	msg("INIT: setting tty device paramters\n");

        if (tcgetattr(fd, &tty)) {
		perror("get term attr");
		return 1;
        }

        cfsetispeed(&tty, B9600);
	cfmakeraw(&tty);

        tty.c_iflag &= ~(IXON | IXOFF | IXANY);
        tty.c_lflag = 0;
        tty.c_cflag |= (CLOCAL | CREAD);
        tty.c_cflag &= ~(PARODD | CSTOPB | CRTSCTS);

        if (tcsetattr(fd, TCSANOW, &tty)) {
                perror("set term attr");
                return -1;
        }

        return 0;
}

#define pf(desc,fn)							\
	({								\
		unsigned long long __f_v = rd.fn;			\
									\
		msg("%16s:  %10llu (%012llx)\n", desc, __f_v, __f_v);	\
	})

const char *time_units[] = { "ns", "us", "ms", "s" };
#define pf_time(desc,fn)						\
	({								\
		unsigned long long __f_v = rd.fn;			\
		unsigned long long __t = __f_v * 10;			\
		int __r = 0;					       	\
									\
		while (__r < 3 && __t > 999) {				\
			__r++;						\
			__t /= 1000;					\
		}							\
									\
		msg("%16s:  %10llu (%012llx) %3llu%s\n",		\
		    desc, __f_v, __f_v, __t, time_units[__r]);		\
	})

static int process_data(int fd)
{
	struct reg_dump rd = { 0 };
	struct statistic *stat = (void *)&rd;
	char *buf = (void *)&rd;
	int chars_in;
	int rec = 0;
	unsigned short addr = 0;

	chars_in = 0;

	while (1) {
		ssize_t n;

		n = read(fd, buf + chars_in, 1);
		if (n < 0) {
			perror("Read console");
			exit(1);
		}
		if (n != 1) {
			msg("Large read!?\n");
			exit(2);
		}

		chars_in++;

		if (chars_in == ADDR_LEN)
			addr = rd.__addr;

		if (addr <= ADDR_STAT_MAX &&
		    chars_in == sizeof(struct statistic)) {
			unsigned long long val = stat->value;

			if (!addr)
				print_start_line(&rec, "Statistics dump");

			chars_in = 0;

			/* don't print zero-statistics */
			if (!val)
				continue;

			msg("%03hx: %16llu (%09llx)%c", addr, val, val,
			    rec++ & 1 ? '\n' : '\t');
		}

		if (addr > ADDR_STAT_MAX &&
		    chars_in == sizeof(struct reg_dump)) {
			print_start_line(&rec, "Register dump");

			pf("REG packet len", pkt_len);
			pf_time("REG interval", pkt_ival);
			pf_time("REG delay", pkt_delay);
			pf("STAT tx frames", tx_frames);
			pf("STAT RX ctrl", rx_control);
			pf("STAT RX data", rx_data);
			pf("STAT TS uflow", ts_uflow);

			chars_in = 0;
		}
	}

	return 0;
}

int main(int argc, char **argv)
{
	int fd;

	if (argc < 2) {
		printf("Usage: %s <ttyDevice>\n", argv[0]);
		return 1;
	}

	msg("INIT: using %s\n", argv[1]);

	fd = open(argv[1], O_RDONLY | O_NOCTTY | O_SYNC);
	if (fd < 0) {
		perror("Open console");
		return 1;
	}
	if (term_init(fd))
		return 2;

	msg("INIT: done.\n\n");
	process_data(fd);

	close(fd);

	return 0;
}
