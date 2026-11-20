# prebuilt

`mosquitto-gdb` 扩展（私有源码）的预编译产物，供 `broker.Dockerfile` 打包进镜像。

- 源码：私有仓库 `gdb/mosquitto-gdb`，不随本仓库发布
- 构建环境：与 `broker.Dockerfile` 一致的 `debian:trixie-slim` + 同版本 mosquitto
- 重新生成：`./build-gdb.sh [源码目录]`（默认读取 `GDB_SRC` 或 `~/.../mosquitto-gdb`）

产物按架构命名：`libgdb-<arch>.so`。镜像构建时 `broker.Dockerfile` 会用 `TARGETARCH`
选择对应文件安装到 `/usr/lib/libgdb.so`；当前仓库仅有 `amd64` 产物，其他架构会跳过安装。
