TARGET = FileTransfer.dylib

SYSROOT = /var/mobile/sysroot

CC = gcc
# CC = /home/h2co3/ios-toolchain/toolchain/pre/bin/arm-apple-darwin9-gcc
LD = $(CC)
CFLAGS = -isysroot $(SYSROOT) \
	 -Wall \
	 -std=gnu99 \
	 -c

LDFLAGS = -isysroot $(SYSROOT) \
	  -w \
	  -dynamiclib \
	  -lobjc \
	  -lactivator \
	  -framework Foundation \
	  -framework UIKit

OBJECTS = FileTransfer.o FTViewController.o FTChooseViewController.o FTListener.o TCPHelper/NSError+TCPHelper.o TCPHelper/tcpconnect.o TCPHelper/TCPHelper.o

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^
	cp $@ /Library/MobileSubstrate/DynamicLibraries

%.o: %.m
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(OBJECTS) $(TARGET) *~

