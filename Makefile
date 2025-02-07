VPATH = src

AS = as6502
CC = cc6502
LN = ln6502
PC = petcat


ETHLOAD   = etherload.osx
M65FTP    = mega65_ftp.osx
C1541     = c1541
XMEGA65   = /Applications/Mega65/xmega65.app/Contents/MacOS/xmega65
ACME = /Applications/acme/acme 

# Common source files
ASM_SRCS =  $(wildcard src/*.s) $(wildcard src/mega65/*.s) #kernfileio.s dirent.s
C_SRCS = $(wildcard src/*.c) $(wildcard src/mega65/*.c)
# Object files
OBJS = $(ASM_SRCS:src/%.s=obj/%.o) $(C_SRCS:src/%.c=obj/%.o)
OBJS_DEBUG = $(ASM_SRCS:%.s=obj/%-debug.o) $(C_SRCS:%.c=obj/%-debug.o)
DEPS      = $(OBJS:%.o=%.d)

export ETHLOAD_IP_PARAM

all: dj.d81 

debug_xemu: dj.d81
	@echo "--------------------------------------------------"
	@echo "Starting Xemu..."
	@echo "Make sure a tmux session named 'mmxemu' is running"
	@echo "Use 'xemu_tmux_session.sh' to create one"
	@echo "--------------------------------------------------"
#   tmux send-keys -t mmxemu "$(XMEGA65) -uartmon :4510 -8 dj.d81 -besure -curskeyjoy -videostd 0" C-m
	$(XMEGA65) -uartmon :4510 -8 dj.d81 -besure -curskeyjoy -videostd 0

obj/%.o: %.s
	as6502 --target=mega65 --list-file=$(@:%.o=%.lst) -o $@ $<


obj/%.o: %.c
	cc6502 --target=mega65 --core 45gs02  --no-cross-call  -I ./include --list-file=$(@:%.o=%.lst) -o $@ $<

obj/%-debug.o: %.s
	as6502 --target=mega65 --debug --list-file=$(@:%.o=%.lst) -o $@ $<

obj/%-debug.o: %.c
	cc6502 --target=mega65 --debug --list-file=$(@:%.o=%.lst) -o $@ $<

test-fileio.prg:  $(OBJS)
	ln6502 --target=mega65 mega65-plain.scm  -o $@ $^  --output-format=prg --list-file=hello-mega65.lst
#	$(ACME) -f cbm -o install.prg -l install.lst -r install.rpt ./src/install.s

    #ln6502 --target=mega65 mega65-plain.scm  mega65-banked.scm  -o $@ $^ --output-format=prg --list-file=hello-mega65.lst
# 	launch emulator
#	test -f hello.prg && /Applications/Mega65/bin/xmega65 -besure -uartmon :4510 -8 /Users/giovanni.pozzobon/Documents/GitHub/mega65editor/DEVJOB.D81 -prg hello.prg
#	launch Mega65
#	test -f hello.prg && etherload.osx -R /Users/giovanni.pozzobon/Documents/MEGA65/Rom/920407.bin -m DEVJOB.D81 -r hello.prg

test-fileio.elf: $(OBJS_DEBUG)
	ln6502 --target=mega65 mega65-plain.scm --debug -o $@ $^ --list-file=hello-debug.lst --semi-hosted

dj.d81: test-fileio.prg
	echo "creating  dj.d81 disk image"; 
#	$(PC)  -w65 -o "load.prg" -- "load.bas"
#	$(PC)  -w65 -o "help.seq" -- "help.txt"
#	$(C1541) -format "jobond test,m1" d81 dj.d81; 
#	$(C1541) -attach dj.d81 -write test-fileio.prg hello -write CHARROM.M65 helpjedit,s; 

clean:
	-rm $(OBJS) $(OBJS:%.o=%.lst) $(OBJS_DEBUG) $(OBJS_DEBUG:%.o=%.lst)
	-rm test-fileio.elf test-fileio.prg test-fileio-mega65.lst test-fileio-debug.lst dj.d81
	-rm *.raw

xemu:
#	test -f hello.prg && /Applications/Mega65/bin/xmega65 -besure -uartmon :4510 -8 /Users/giovanni.pozzobon/Documents/GitHub/mega65editor/DEVJOB.D81 -prg hello.prg
#	$(XMEGA65) -uartmon :4510 -8 dj.d81 -besure -curskeyjoy -videostd 0
	$(XMEGA65) -uartmon :4510 -prg test-fileio.prg -besure -curskeyjoy -videostd 0

mega65:
#	test -f hello.prg && etherload.osx -R /Users/giovanni.pozzobon/Documents/MEGA65/Rom/920407.bin -m DEVJOB.D81 -r hello.prg
	test -f test-fileio.prg && $(ETHLOAD) $(ETHLOAD_IP_PARAM) -m dj.d81

jtag:
#	m65.osx -l /dev/cu.usbserial-B002YK9V -@ hello.prg@2001	
	$(M65FTP)  $(ETHLOAD_IP_PARAM) -e -c"put dj.d81"
	