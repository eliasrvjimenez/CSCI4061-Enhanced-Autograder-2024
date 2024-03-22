# Variables
CC=gcc
CFLAGS=-Wall -g

SRCDIR=src
INCDIR=include
LIBDIR=lib

SOL_DIR=solutions
PROJECT_NAME=project2

SOURCE_FILE=$(SRCDIR)/template.c
N ?= 8
BINARIES=$(addprefix $(SOL_DIR)/sol_, $(shell seq 1 $(N)))

# Default target
auto: autograder $(BINARIES)

mq_auto: mq_autograder worker $(BINARIES)

# Compile autograder
autograder: $(SRCDIR)/autograder.c $(LIBDIR)/utils.o
	$(CC) $(CFLAGS) -I$(INCDIR) -o $@ $< $(LIBDIR)/utils.o 

# Compile mq_autograder
mq_autograder: $(SRCDIR)/mq_autograder.c $(LIBDIR)/utils.o
	$(CC) $(CFLAGS) -I$(INCDIR) -o $@ $< $(LIBDIR)/utils.o

# Compile worker
worker: $(SRCDIR)/worker.c $(LIBDIR)/utils.o
	$(CC) $(CFLAGS) -I$(INCDIR) -o $@ $< $(LIBDIR)/utils.o

# Compile utils.c into utils.o
$(LIBDIR)/utils.o: $(SRCDIR)/utils.c
	$(CC) $(CFLAGS) -I$(INCDIR) -c -o $@ $< 

# Compile worker.c into worker.o
$(LIBDIR)/worker.o: $(SRCDIR)/worker.c
	$(CC) $(CFLAGS) -I$(INCDIR) -c -o $@ $<

# Compile template.c into N binaries
$(SOL_DIR)/sol_%: $(SOURCE_FILE)
	mkdir -p $(SOL_DIR)
	$(CC) $(CFLAGS) -o $@ $<

# Compile mq_template.c into N binaries
$(SOL_DIR)/mq_sol_%: $(MQ_SRC_FILE) $(LIBDIR)/utils.o
	mkdir -p $(SOL_DIR)
	$(CC) $(CFLAGS) -I${INCDIR} -o $@ $< $(LIBDIR)/utils.o

# Cases
exec: CFLAGS += -DEXEC
exec: auto

redir: CFLAGS += -DREDIR
redir: auto

pipe: CFLAGS += -DPIPE
pipe: auto

mqueue: CFLAGS += -DMQUEUE
mqueue: mq_auto

# Test case 1: "make test1_exec N=8"
test1_exec: exec
	./autograder solutions 1 2 3

# Clean the build
clean:
	rm -f autograder mq_autograder worker
	rm -f solutions/sol_*
	rm -f $(LIBDIR)/*.o
	rm -f input/*.in output/*
	rm -rf test_results

zip:
	@make clean
	zip -r $(PROJECT_NAME).zip include lib src input output solutions expected Makefile README.md

test-setup:
	@chmod u+x testius
	@chmod -R u+x test_cases/
	@chmod -R u+x autograder
	rm -rf test_results/*

clean-tests:
	rm -rf autograder test_results results.txt scores.txt

ifdef testnum
test-simple: clean-tests exec test-setup
	@rm -f results.txt
	@./testius test_cases/simple.json -v -n "$(testnum)"
else
test-simple: clean-tests exec test-setup
	@./testius test_cases/simple.json -v
endif

test-exec:
	@make clean-tests exec test-setup
	@./testius test_cases/exec.json -v

test-redir:
	@make clean-tests redir test-setup
	@./testius test_cases/redir.json -v

test-pipe:
	@make clean-tests pipe test-setup
	@./testius test_cases/pipe.json -v

test-all: test-exec test-redir test-pipe

test-mq-autograder:
	@make clean clean-tests mqueue
	@./testius test_cases/mq.json -v

.NOTPARALLEL: exec redir pipe test-setup

kill:
	@for number in $(shell seq 1 $(N)); do \
		pgrep -f "sol_$$number" > /dev/null && (pkill -SIGKILL -f "sol_$$number" || echo "Could not kill sol_$$number") || true; \
	done

.PHONY: auto clean exec redir pipe zip test-setup test-simple test-mq-autograder kill test-exec test-redir test-pipe test-all clean-tests
