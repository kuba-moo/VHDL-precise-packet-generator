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
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>
#include <inttypes.h>

#define _BSD_SOURCE 1

#define REG_CSR		0x00
#define REG_PKT_LEN	0x04
#define REG_PKT_IVAL	0x08
#define REG_PKT_DLY	0x0c
#define REG_CNT_UFLOW	0x10
#define REG_CNT_TX	0x18
#define REG_CNT_RX	0x20
#define REG_STATS	0x28

#define CSR_RST		0x01 /* full hw reset */
#define CSR_RST_STATS	0x02 /* reset stats and counters */
#define CSR_PKT_TX_EN	0x04 /* enable packet generation */
#define CSR_PKT_WE	0x80 /* packet mem write enable */

#define ETH_OVERHEAD 20 /* PREAMBLE + IFG */

#define pr(fmt, ...) printf(fmt, ##__VA_ARGS__)
#define msg(fmt, ...) fprintf(stderr, fmt, ##__VA_ARGS__)
#define err(fmt, ...) fprintf(stderr, "ERROR: " fmt, ##__VA_ARGS__)

typedef int (*op_cb)(int fd, char **argv);

struct operation {
	const char *name;
	op_cb callback;
	int args;
};

struct uart_request {
	unsigned wr : 1;
	unsigned addr : 6;

	uint32_t val;
} __attribute__((packed));

static int usage(char *name, char *reason)
{
	err("%s\n", reason);

	pr("%s <tty_name> <cmd>\n"
	   "\n"
	   "Commands:\n"
	   "   hw_reset\t\treset whole board\n"
	   "   reset_stats\t\treset statistics\n"
	   "   enable_tx <0/1>\treset statistics\n"
	   "   reg_read <addr>\tread specific register\n"
	   "   reg_write <addr> <val> write specific register\n"
	   "   reg_dump\t\tdump all registers\n"
	   "   set_ival <ival>\tset interval between packets\n"
	   "   set_dly <dly>\tset expected delay of returning packet\n"
	   "   load_pkt <file>\tload packet from file\n"
	   "   stats\t\tdump stats\n"
	   "   set_mbps <mbps>\tset ival to achieve mbps\n"
	   "   set_pps <pps>\tset ival to achieve pps\n"
	   "   set_full_speed\tset ival to get 100Mbps\n"
	   "\n",
	   name);

	return 1;
}

static int uart_init(int fd)
{
	struct termios tty = { 0 };

	msg("INIT: setting tty device paramters\n");

        if (tcgetattr(fd, &tty)) {
		perror("get term attr");
		return 1;
        }

        cfsetspeed(&tty, B115200);
	cfmakeraw(&tty);

        tty.c_iflag &= ~(IXON | IXOFF | IXANY);
        tty.c_lflag = 0;
        tty.c_cflag |= (CLOCAL | CREAD);
        tty.c_cflag &= ~(PARODD | CSTOPB | CRTSCTS);

        if (tcsetattr(fd, TCSANOW, &tty)) {
                perror("set term attr");
                return 1;
        }

        return 0;
}

static int read_int_dec_or_hex(const char *str)
{
	int ret;

	if (sscanf(str, "0x%x", &ret) > 0)
		return ret;

	if (sscanf(str, "%d", &ret) > 0)
		return ret;

	err("Unable to parse value %s\n", str);

	return 0;
}

static uint32_t send_req(int fd, int addr, uint32_t val, int wr)
{
	struct uart_request req = { 0 };
	char *buf = (void *)&req;
	int len, ret;

	req.wr = wr;
	req.val = val;
	req.addr = addr;

	ret = write(fd, &req, sizeof(req));
	if (ret < 5)
		err("Bad write: %d [%d %m]", ret, errno);

	len = 5;
	while (len) {
		ret = read(fd, buf + (5 - len), len);
		if (ret < 0)
			err("Bad read: %d [%d %m]", ret, errno);
		len -= ret;
	}

	return req.val;
}

#define reg_read(fd, addr) send_req(fd, addr, -1, 0)
#define reg_write(fd, addr, val) send_req(fd, addr, val, 1)

#define get_real_pkt_len(fd)						\
	({ (reg_read(fd, REG_PKT_LEN) & 0xffff) + ETH_OVERHEAD; })

static int u_hw_reset(int fd, char **argv)
{
	argv = argv;

	reg_write(fd, REG_CSR, CSR_RST);

	return 0;
}

static int u_reset_stats(int fd, char **argv)
{
	argv = argv;

	reg_write(fd, REG_CSR, CSR_RST_STATS);
	reg_write(fd, REG_CSR, 0);

	return 0;
}

static int u_enable_tx(int fd, char **argv)
{
	argv = argv;

	reg_write(fd, REG_CSR,
		  read_int_dec_or_hex(argv[0]) ? CSR_PKT_TX_EN : 0);

	return 0;
}

static int u_reg_read(int fd, char **argv)
{
	int addr;

	addr = read_int_dec_or_hex(argv[0]);
	pr("0x%08x\n", reg_read(fd, addr));

	return 0;
}

static int u_reg_write(int fd, char **argv)
{
	int addr;
	uint32_t val;

	addr = read_int_dec_or_hex(argv[0]);
	val = read_int_dec_or_hex(argv[1]);
	pr("0x%08x\n", reg_write(fd, addr, val));

	return 0;
}

static int u_reg_dump(int fd, char **argv)
{
	uint32_t val;
	uint64_t val64;
	int len, ival;

	argv = argv;

#define MASK(nibs) ((1ULL << nibs*4) - 1)
#define rp(__n__, __a__, __m__)						\
	({								\
		val = reg_read(fd, __a__)  & MASK(__m__);		\
		pr(#__n__ ":     \t0x%0" #__m__ "x (%d)\n",		\
		   val, val);						\
		val;							\
	})
#define rp64(__n__, __a__, __m__)					\
	({								\
		val64 = reg_read(fd, __a__ + 4)  & MASK(__m__);		\
		val64 <<= 32;						\
		val64 |= reg_read(fd, __a__)  & MASK(__m__);		\
		pr(#__n__ ":     \t0x%0" #__m__ PRIx64" (%"		\
		   PRIu64 ")\n", val64, val64);				\
		val64;							\
	})

	rp(csr, 0, 2);
	len = rp(pkt_len, 4, 4);
	ival = rp(pkt_ival, 8, 8);
	rp(exp_delay, 12, 8);
	rp64(cnt_uflow, 16, 9);
	rp64(cnt_tx, 24, 9);
	rp64(cnt_rx, 32, 9);

	if (ival)
		pr("\tpps: %d\tMbps: %d\n", 100000000/ival,
		   800*(len + ETH_OVERHEAD)/ival);

	return 0;
}

static int u_set_ival(int fd, char **argv)
{
	uint32_t val;

	val = read_int_dec_or_hex(argv[0]);
	reg_write(fd, REG_PKT_IVAL, val);

	return 0;
}

static int u_set_dly(int fd, char **argv)
{
	uint32_t val;

	val = read_int_dec_or_hex(argv[0]);
	reg_write(fd, REG_PKT_DLY, val);

	return 0;
}

static int u_load_pkt(int fd, char **argv)
{
	FILE *fp;
	uint8_t byte;
	int addr = 8; /* Skip PREAMBLE and SFD */

	fp = fopen(argv[0], "r");
	if (!fp) {
		perror("cannot open packet file");
		return 1;
	}

	while (!feof(fp)) {
		if (fscanf(fp, "%hhx", &byte) < 1)
			break;

		msg("\rLoading... %d", addr - 8);

		reg_write(fd, REG_CSR,
			  CSR_PKT_WE | (byte << 8) | (addr++ << 16));
		reg_write(fd, REG_CSR, 0);
	}
	msg("\n");

	reg_write(fd, REG_PKT_LEN, addr - 8);

	return 0;
}

static int u_stats(int fd, char **argv)
{
#define N_SAMPLES 512
	uint64_t stats[N_SAMPLES], sum = 0;
	int i;

	argv = argv;

	for (i = 0; i < N_SAMPLES; i++) {
		msg("\rReading... %d", i);

		reg_write(fd, 0x28, i);

		stats[i] = reg_read(fd, 0x34);
		stats[i] <<= 32;
		stats[i] |= reg_read(fd, 0x30);
	}
	msg("\n");

#define pr_stat(i)							\
	({								\
		if (i & 0x100)						\
			pr("%03x: %9" PRIu64 " (%3d = %dms)\n",		\
			   i, stats[i], i, (i-255)*256/100*255/1000);	\
		else							\
			pr("%03x: %9" PRIu64 " (%3d = %dus)\n",		\
			   i, stats[i], i, i*256/100);			\
	})


	for (i = 0; i < N_SAMPLES; i++) {
		if (stats[i])
			pr_stat(i);

		sum += stats[i];
	}

	pr("Sum samples: 0x%09" PRIx64 " (%" PRIu64 ")\n", sum, sum);

	return 0;
}

static int u_set_mbps(int fd, char **argv)
{
	uint32_t mbps;
	int len;

	mbps = read_int_dec_or_hex(argv[0]);
	if (mbps > 100) {
		err("Overload, this is only 100Mbps Ethernet...\n");
		return 1;
	}

	len = get_real_pkt_len(fd);
	reg_write(fd, REG_PKT_IVAL, 800*len/mbps);

	return 0;
}

static int u_set_pps(int fd, char **argv)
{
	uint32_t pps;
	int len;

	pps = read_int_dec_or_hex(argv[0]);
	len = get_real_pkt_len(fd);
	if (pps * len * 8 >= 100000000) {
		err("Overload, this is only 100Mbps Ethernet... %d\n",
		    pps * len * 8);
		return 1;
	}

	reg_write(fd, REG_PKT_IVAL, 100000000/pps);

	return 0;
}

static int u_set_full_speed(int fd, char **argv)
{
	char *hundred = "100";

	argv = argv;

	return u_set_mbps(fd, &hundred);
}

#define OP(name, args) { #name, u_##name, args }

struct operation ops[] = {
	OP(hw_reset, 0),
	OP(reset_stats, 0),
	OP(enable_tx, 1),
	OP(reg_read, 1),
	OP(reg_write, 2),
	OP(reg_dump, 0),
	OP(set_ival, 1),
	OP(set_dly, 1),
	OP(load_pkt, 1),
	OP(stats, 0),
	OP(set_mbps, 1),
	OP(set_pps, 1),
	OP(set_full_speed, 0),
};

static struct operation *string_switch(int argc, char **argv)
{
	unsigned i;

	if (argc < 1)
		return NULL;

	for (i = 0; i < sizeof(ops)/sizeof(ops[0]); i++)
		if (!strcmp(argv[0], ops[i].name))
			return ops + i;

	return NULL;
}

int main(int argc, char **argv)
{
	int fd;
	struct operation *op;

	if (argc < 2)
		return usage(argv[0], "name the console device");

	msg("INIT: using %s\n", argv[1]);

	fd = open(argv[1], O_RDWR | O_NOCTTY | O_SYNC);
	if (fd < 0) {
		perror("Open console");
		return 1;
	}
	if (uart_init(fd))
		return 1;

	msg("INIT: done.\n\n");

	op = string_switch(argc - 2, argv + 2);
	if (!op)
		return usage(argv[0], "unrecognized command");
	if (op->args > argc - 3)
		return usage(argv[0], "this command needs more params");

	return op->callback(fd, argv + 3);
}
