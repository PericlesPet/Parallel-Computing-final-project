OPENMP=0
DEBUG=0
CUDA=1

OBJ=main.o test.o args.o utils.o

VPATH=./src/:./
EXEC=cuda-triangles
SLIB=lib${EXEC}.so
ALIB=lib${EXEC}.a
OBJDIR=./obj/

CC=nvcc

AR=ar
ARFLAGS=rcs
OPTS=-Ofast
LDFLAGS= -lm -pthread
COMMON= -Iinclude/ -Isrc/
CFLAGS=-Wall -Wno-unknown-pragmas -Wfatal-errors -fPIC

ifeq ($(CUDA),1)
CC=nvcc
CFLAGS+= -arch=sm_50
endif

ifeq ($(OPENMP), 1)
CFLAGS+= -fopenmp
endif

ifeq ($(DEBUG), 1)
OPTS=-O0 -g
COMMON= -Iinclude/ -Isrc/
endif

CFLAGS+=$(OPTS)

OBJS = $(addprefix $(OBJDIR), $(OBJ))
DEPS = $(wildcard src/*.h) Makefile 

all: obj $(SLIB) $(ALIB) $(EXEC)

$(EXEC): $(OBJS)
	$(CC) $(COMMON) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(ALIB): $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

$(SLIB): $(OBJS)
	$(CC) $(CFLAGS) -shared $^ -o $@ $(LDFLAGS)

$(OBJDIR)%.o: %.c $(DEPS)
	$(CC) $(COMMON) $(CFLAGS) -c $< -o $@

obj:
	mkdir -p obj

.PHONY: clean

clean:
	rm -rf $(OBJS) $(SLIB) $(ALIB) $(EXEC) $(OBJDIR)/*
