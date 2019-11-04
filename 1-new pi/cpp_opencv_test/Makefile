CC=g++
# 可运行文件
TARGET=main
# C文件
SRCS=main.cpp
# 目标文件
OBJS=$(SRCS:.cpp=.o)
# 库文件
# DLIBS = -lopencv_core -lopencv_imgproc -lopencv_highgui
DLIBS=$(shell pkg-config --libs opencv)
# 链接为可运行文件
$(TARGET):$(OBJS)
	$(CC) -o $@ $^ $(DLIBS)
clean:
	rm -f $(TARGET) $(OBJS)
# 编译规则 $@代表目标文件 $< 代表第一个依赖文件
%.o:%.cpp
	$(CC) -o $@ -c $<
