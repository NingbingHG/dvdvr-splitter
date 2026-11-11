# DVD-VR 分割器 v2.1.2

把 DVD-RAM / DVD-RW（VR 模式）录像盘里的 `VR_MOVIE.VRO` **按节目无损拆成一个个 MPG**。
不重新编码、不需要 ffmpeg、切割点精确到 VOBU。

> 本项目是 [spinningbanana/dvd-rtr-vmg0-splitter](https://github.com/spinningbanana/dvd-rtr-vmg0-splitter)（GPL-3.0）的重写版：
> 修掉了它解析 IFO 的错误，并加了三语界面、按录制时间命名等功能。
>
> **测试设备：日立 Hitachi DZ-GX20（DVD-RAM 摄像机，VR 模式）**

---

## 一、修复的 Bug

| # | 现象 | 根因 | 修复 |
|---|---|---|---|
| 1 | 一张只有 2 个节目的盘，导出 **30 个文件，其中 27 个 0 字节** | 把 IFO 的 `0x100`（真正的 `pgit_sa`＝**节目表**）当成“片段表”，`0x130`（`def_psi_sa`＝标题文字）当成“标题表”；再用 `0x6540`/`0x32A0` 两字节标记在节目表里“猜”记录 | 按 RTR_VMG 真实结构解析：`pgiti → vob_format[] → pgi_gi → vvobi_sa[] → vvob → vobu_map`，每处偏移都做越界检查 |
| 2 | 整部 92 秒的片子被塞进一个 `17.mpg`，其余为空 | 假记录的“时长”是乱的，只有一条被读成超大值 | 每个节目在 VRO 里是一段**连续字节区间**（`vob_off×2048`，长度 `Σvobu_size×2048`），直接按字节拷贝 |
| 3 | ffmpeg 报 `Invalid duration for option t: 1.111e-05` | 解析出的时长只有 1 个 PTS tick（1/90000 秒） | 不再用时间切片；导出前后都校验字节数 |
| 4 | 必须装 ffmpeg 并放进 PATH | 靠 ffmpeg 按时间切 | 默认**不需要 ffmpeg**；`--remux` 才是可选项 |
| 5 | 长录像导出时界面“假死” | 切割跑在 GUI 主线程 | 改到 Worker 线程，带进度条与「取消」 |
| 6 | 出错只弹一句 “Failed”，或静默生成空文件 | 宽泛的 `except: pass` | 明确报错：不是 DVD-VR IFO、IFO 损坏、IFO 与 VRO 不匹配、CPRM 加密 |
| 7 | 输出目录选在光盘/虚拟光驱上，弹一大段 `Traceback … WinError 685` | `os.access()` 对光盘误判为可写，`mkdir` 才失败 | 改为**真实写入测试**；失败时提示“输出目录不可写，请换本地硬盘目录” |
| 8 | 从摄像机 USB 读盘读到一半，弹 `OSError: [Errno 22] Invalid argument` | 单次大块读取、无重试；摄像机**电池耗尽/USB 断线**后句柄失效 | 64 KB 分块 + 3 次重试（每次重新 seek）；错误提示直接列出“**摄像机断电/电池耗尽**、**数据线松动/被拔出**、光盘划痕、虚拟光驱掉线”；新增 `--skip-errors` 跳过坏块 |

## 二、新增的功能

- **中文 / 日本語 / English** 三语界面，右上角切换，选择会记住（`%APPDATA%\DVDVRSplitter\config.json`）；
  命令行 `--lang zh|ja|en`，环境变量 `DVDVR_LANG` 亦可。
- **按 IFO 里的录制日期时间命名**：`2026-11-11_17-36-20.mpg`；无时间戳时退回 `program_01.mpg`；重名自动加 `_2`。
- **节目列表**：显示每个节目的录制时间、时长、大小、在 VRO 里的字节偏移，可勾选导出。
- **进度条 + 取消**，导出在后台线程，界面不卡。
- **`--skip-errors`**：光盘有划痕/设备接触不良时跳过坏块继续导出，跳过的位置写进日志。
- **`--remux`**：可选，用 ffmpeg `-c copy` 重新封装成更规整的 MPEG-PS。
- **命令行模式**：`--list` 看盘、`--programs 1,2` 选节目、`-o` 指定输出。
- **单文件 exe**（本 Release 附带），免安装 Python。

## 三、测试记录（日立 DZ-GX20）

| 盘 | 节目数 | 总时长 | 总大小 | 结果 |
|---|---|---|---|---|
| A | 2 | 00:01:32.592 | 66.6 MB | #1 62.562 s / 45.0 MB → **1875 帧**；#2 30.030 s / 21.6 MB → **900 帧**；字节数完全吻合，节目 2 起点正好等于节目 1 终点 |
| B | 4 | 00:04:02.742 | 174.7 MB | 解析正确（1:02.562 / 0:30.030 / 0:24.024 / 2:06.126）；导出途中因摄像机电池耗尽中断，触发第 8 条修复 |

校验方式：`ffprobe -count_frames` 对比帧数、`-c copy` 整盘解码对比 2775 帧。

## 四、使用

### 图形界面

- **免安装**：直接运行 `DVDVR-Splitter.exe`（本 Release 附带）。
- **源码运行**：`pip install PySide6` 后 `python dvdvr_split.py`（或双击 `run.cmd`）。

步骤：选 `DVD_RTAV` 目录 → 「读取光盘信息」→ 勾选节目 → 选输出目录（**必须是本地硬盘**）→ 「开始导出」。

### 命令行

```bat
:: 列出节目
dvdvr_split.py --ifo G:\DVD_RTAV\VR_MANGR.IFO --vro G:\DVD_RTAV\VR_MOVIE.VRO --list

:: 导出全部 / 指定节目 / 换语言
dvdvr_split.py --ifo ... --vro ... -o D:\Videos\DVD_OUT
dvdvr_split.py --ifo ... --vro ... -o D:\Videos\DVD_OUT --programs 2 --lang ja

:: 光盘有划痕：跳过坏块
dvdvr_split.py --ifo ... --vro ... -o D:\Videos\DVD_OUT --skip-errors
```

退出码：`0` 成功，`2` 解析/导出错误（原因打印到 stderr），`130` 取消。

## 五、为什么它能无损切割

```
0x000  "DVD_RTR_VMG0"
0x100  pgit_sa   → pgiti{ zero(2), nr_of_pgi(1), nr_of_vob_formats(1), pgit_ea(4) }
                   vob_format_t × nr_of_vob_formats（60 字节/个）
                   pgi_gi{ nr_of_programs(2) }
                   vvobi_sa[program]（4 字节，相对 pgit_sa）
0x130  def_psi_sa → 标题文字

vvob_t（21 字节）: attr(2) 录制时间(5) data1(1) format_id(1) v_s_ptm(4+2) v_e_ptm(4+2)
  然后 (attr & 0x80 ? adj_vob(12) : 0) + 2
       vobu_map{ n_time(2), n_vobu(2), time_off(2), vob_off(4 扇区) }
       time_info × n_time（7 字节）
       vobu_info × n_vobu（3 字节，后 14 位＝扇区数）
```

于是节目 N 在 VRO 中是连续区间：

```
起点 = vob_off × 2048
长度 = Σ(vobu_size) × 2048
```

## 六、已知限制

- 只支持 VR 模式 `DVD_RTR_VMG0`；DVD-Video（`VIDEO_TS`）不支持，会明确报错。
- CPRM 加密盘只能警告，无法解密。
- 一个节目导出成一个文件；节目内部若还有 cell 需要细分，尚未实现。
- 输出是原始 VOB 字节流（MPEG-PS + DVD 导航包），VLC / PotPlayer / MPC-HC 可直接播放。

## 七、版本历史

| 版本 | 日期 | 内容 |
|---|---|---|
| 2.0.0 | 2026-11-11 | 重写：正确解析 IFO、按字节无损导出、校验与清晰报错、GUI 线程化 |
| 2.1.0 | 2026-11-12 | 中/日/英界面；按 IFO 录制时间命名；`--lang` |
| 2.1.1 | 2026-11-12 | 输出目录不可写时给可读提示（不再弹 traceback）；默认目录真实可写测试 |
| 2.1.2 | 2026-11-12 | 读盘 64 KB 分块 + 重试；错误提示列出电池/数据线原因；新增 `--skip-errors` |

## 八、许可与致谢

- 许可：**GPL-3.0**（沿用上游项目）
- 致谢：[spinningbanana/dvd-rtr-vmg0-splitter](https://github.com/spinningbanana/dvd-rtr-vmg0-splitter)（原始思路与 GUI 灵感）、
  [pixelb/dvd-vr](https://github.com/pixelb/dvd-vr)（RTR_VMG 结构的 C 参考实现）
