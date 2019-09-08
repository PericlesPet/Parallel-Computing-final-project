DEBUG=0
OBJ=main.o test.o cudaTriangles.o utils.o

VPATH=./src/:./
EXEC=cuda-triangles-exe
SLIB=lib${EXEC}.so
ALIB=lib${EXEC}.a
OBJDIR=./obj/

AR=ar
ARFLAGS=rcs
# OPTS=-Ofast
LDFLAGS= -Xcompiler -fPIC -Xcompiler -lm 
COMMON= -Iinclude/ -Isrc/

CC=nvcc
CFLAGS = -arch=sm_50

ifeq ($(DEBUG), 1)
OPTS=-O0 -g
COMMON= -Iinclude/ -Isrc/
endif

CFLAGS+=$(OPTS)

OBJS = $(addprefix $(OBJDIR), $(OBJ))
DEPS = $(wildcard src/*.h) Makefile 

all: obj $(ALIB) $(EXEC)
# $(SLIB)
# $(LDFLAGS)
# $(SLIB): $(OBJS)
# $(CC) $(CFLAGS) -shared $(LDFLAGS) $^ -o $@

$(EXEC): $(OBJS)
	$(CC) $(COMMON) $(CFLAGS) $^ -o $@ 
	

$(ALIB): $(OBJS)
	$(AR) $(ARFLAGS) $@ $^


$(OBJDIR)%.o: %.cu $(DEPS)
	$(CC) $(COMMON) $(CFLAGS) -c $< -o $@

obj:
	mkdir -p obj

.PHONY: clean

clean:
	rm -rf $(OBJS) $(SLIB) $(ALIB) $(EXEC) $(OBJDIR)/*
