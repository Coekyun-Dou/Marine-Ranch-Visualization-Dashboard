# 水下鱼类计数系统开发文档

## 目录
1. [系统开发概述](#系统开发概述)
2. [技术架构设计](#技术架构设计)
3. [详细技术流程](#详细技术流程)
4. [运行逻辑说明](#运行逻辑说明)
5. [核心模块解析](#核心模块解析)
6. [改进点说明](#改进点说明)

---

## 系统开发概述

### 开发背景
本系统是针对水下鱼类计数场景开发的智能检测系统，基于改进的YOLOv8s目标检测模型，结合PyQt5图形界面，实现了从图像/视频输入到检测结果输出的完整流程。

### 开发流程
1. **需求分析阶段**
   - 确定系统功能需求：支持多种输入源、实时检测、结果统计
   - 确定技术选型：YOLOv8作为检测模型，PyQt5作为GUI框架

2. **模型改进阶段**
   - 基于YOLOv8s架构进行改进
   - 集成CBAM（Convolutional Block Attention Module）注意力机制
   - 针对水下环境进行模型优化

3. **系统开发阶段**
   - 设计并实现登录系统
   - 开发主界面GUI
   - 实现检测线程与UI的交互
   - 集成模型推理功能

4. **测试与优化阶段**
   - 功能测试
   - 性能优化
   - 内存管理优化

---

## 技术架构设计

### 整体架构

```
┌─────────────────────────────────────────────────┐
│              用户界面层 (PyQt5)                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ 登录界面 │  │ 主界面   │  │ 对话框   │    │
│  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────┘
                    ↕ 信号/槽机制
┌─────────────────────────────────────────────────┐
│              业务逻辑层                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │检测线程  │  │模型管理  │  │数据管理  │    │
│  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────┘
                    ↕ API调用
┌─────────────────────────────────────────────────┐
│              深度学习模型层                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ YOLOv8   │  │ CBAM模块 │  │ 后处理   │    │
│  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────────────┐
│              数据层                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ 图像数据 │  │ 视频流   │  │ MySQL   │    │
│  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────┘
```

### 技术栈分层

1. **表示层 (Presentation Layer)**
   - PyQt5: 提供图形用户界面
   - Qt Designer: UI设计工具
   - 信号/槽机制: 实现组件间通信

2. **业务逻辑层 (Business Logic Layer)**
   - 多线程处理: QThread实现检测任务
   - 事件驱动: 响应式UI更新
   - 状态管理: 检测状态控制

3. **数据访问层 (Data Access Layer)**
   - OpenCV: 图像/视频处理
   - PyMySQL: 数据库访问
   - 文件系统: 结果保存

4. **模型层 (Model Layer)**
   - Ultralytics YOLO: 目标检测框架
   - PyTorch: 深度学习后端
   - 自定义模块: CBAM注意力机制

---

## 详细技术流程

### 1. 系统启动流程

```
start.py (入口)
    ↓
创建QApplication
    ↓
显示Login窗口
    ↓
用户输入账号密码
    ↓
验证MySQL数据库
    ↓
验证成功 → 创建MainWindow
    ↓
显示主界面
```

**关键代码位置**:
- `start.py`: 程序入口
- `main/login.py`: 登录逻辑
- `main/innerface.py`: 主界面初始化

### 2. 检测流程

#### 2.1 输入源选择流程

```
用户点击输入按钮
    ↓
判断输入类型:
    ├─ 文件选择 → QFileDialog
    ├─ 摄像头 → cv2.VideoCapture(0)
    └─ RTSP流 → cv2.VideoCapture(rtsp_url)
    ↓
初始化DetThread检测线程
    ↓
设置source属性
    ↓
启动线程
```

#### 2.2 图像/视频处理流程

**图片处理流程**:
```
读取图片 (cv2.imread)
    ↓
发送原始图像到UI (send_raw信号)
    ↓
模型推理 (YOLO.predict)
    ↓
解析检测结果
    ↓
绘制检测框和标签
    ↓
发送结果图像到UI (send_img信号)
    ↓
更新统计信息 (send_statistic信号)
    ↓
保存结果 (可选)
```

**视频处理流程**:
```
打开视频文件 (cv2.VideoCapture)
    ↓
循环读取帧
    ↓
    ├─ 检查暂停状态
    ├─ 读取帧 (cap.read)
    ├─ 更新进度条
    ├─ 发送原始帧
    ├─ 模型推理
    ├─ 绘制结果
    ├─ 发送结果帧
    ├─ 更新统计
    └─ 保存帧 (可选)
    ↓
释放资源
```

**关键代码位置**:
- `main/innerface.py` 的 `DetThread` 类
- `main/innerface.py` 的 `process_image()` 方法
- `main/innerface.py` 的 `process_video()` 方法

### 3. 模型推理流程

```
输入图像预处理
    ↓
letterbox调整尺寸 (保持宽高比)
    ↓
转换为Tensor (BCHW格式)
    ↓
归一化 (0-255 → 0-1)
    ↓
YOLOv8模型前向传播
    ├─ Backbone特征提取
    │   ├─ Conv层
    │   ├─ C2f模块 (包含CBAM)
    │   └─ SPPF模块
    ├─ Neck特征融合
    │   ├─ 上采样
    │   ├─ 特征拼接
    │   └─ C2f模块
    └─ Head检测头
        └─ 输出检测结果
    ↓
后处理
    ├─ 置信度过滤 (conf_threshold)
    ├─ 非极大值抑制 (NMS, iou_threshold)
    └─ 坐标转换 (归一化 → 像素坐标)
    ↓
返回检测结果
```

**关键代码位置**:
- `models/common.py`: 模型组件定义
- `models/conv.py`: 卷积模块（包含CBAM）
- `main/innerface.py`: 模型调用

### 4. UI更新流程

```
检测线程发送信号
    ├─ send_raw → 显示原始图像
    ├─ send_img → 显示检测结果
    ├─ send_statistic → 更新统计表格
    ├─ send_fps → 更新FPS显示
    └─ send_percent → 更新进度条
    ↓
主线程接收信号 (Qt信号/槽机制)
    ↓
更新UI组件
    ├─ show_image() → 更新QLabel显示
    ├─ _update_statistic_ui() → 更新表格
    └─ 其他UI更新
```

**关键代码位置**:
- `main/innerface.py` 的 `show_image()` 方法
- `main/innerface.py` 的 `_update_statistic_ui()` 方法

---

## 运行逻辑说明

### 主程序运行逻辑

#### 1. 初始化阶段

```python
# start.py
app = QApplication(sys.argv)
login_window = Login()
login_window.show()
app.exec_()
```

**执行步骤**:
1. 创建Qt应用程序实例
2. 创建登录窗口
3. 显示登录窗口
4. 进入事件循环

#### 2. 登录验证逻辑

```python
# main/login.py
def login_button(self):
    # 1. 获取用户输入
    Login_User = self.lineEdit.text()
    Login_Passwd = self.lineEdit_2.text()
    
    # 2. 连接MySQL数据库
    conn = pymysql.connect(...)
    
    # 3. 查询用户信息
    cursor.execute(f"SELECT * FROM usertable WHERE user='{Login_User}'")
    
    # 4. 验证密码
    if data[1] == Login_Passwd:
        # 5. 打开主界面
        self.showMainSystem()
```

#### 3. 主界面初始化逻辑

```python
# main/innerface.py - MainWindow.__init__()
def __init__(self):
    # 1. 设置UI
    self.setupUi(self)
    
    # 2. 搜索模型文件
    self.pt_list = os.listdir('./pt')
    self.comboBox.addItems(self.pt_list)
    
    # 3. 创建检测线程
    self.det_thread = DetThread()
    self.det_thread.weights = "./pt/best.pt"
    
    # 4. 连接信号和槽
    self.det_thread.send_img.connect(lambda x: self.show_image(x, self.out_video))
    self.det_thread.send_statistic.connect(self._update_statistic_ui)
    
    # 5. 初始化定时器
    self.mem_timer = QTimer(self)
    self.mem_timer.timeout.connect(self.memory_check)
```

#### 4. 检测线程运行逻辑

```python
# main/innerface.py - DetThread.run()
def run(self):
    # 1. 加载模型
    self.model = YOLO(self.weights, task='detect')
    self.model.to('cpu')
    
    # 2. 判断输入类型
    if self.source.endswith(('.mp4', '.avi', '.mov')):
        self.process_video()  # 视频处理
    else:
        self.process_image()  # 图片处理
```

#### 5. 视频处理循环逻辑

```python
# main/innerface.py - DetThread.process_video()
def process_video(self):
    # 1. 打开视频
    self.cap = cv2.VideoCapture(self.source)
    
    # 2. 获取视频信息
    self.total_frames = int(self.cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    # 3. 循环处理每一帧
    while not self.jump_out and self.cap.isOpened():
        # 3.1 检查暂停状态
        if self.is_paused:
            time.sleep(0.1)
            continue
        
        # 3.2 读取帧
        ret, frame = self.cap.read()
        
        # 3.3 更新进度
        self.frame_count += 1
        self.send_percent.emit(int(self.frame_count / self.total_frames * 1000))
        
        # 3.4 发送原始帧
        self.send_raw.emit(frame)
        
        # 3.5 执行检测
        results = self.model(frame, verbose=False)
        
        # 3.6 绘制结果
        annotated_frame = self.annotate_frame(frame, results[0])
        
        # 3.7 发送结果
        self.send_img.emit(annotated_frame)
        
        # 3.8 更新统计
        class_count = self.get_statistics(results[0])
        self.send_statistic.emit(class_count)
        
        # 3.9 控制帧率
        time.sleep(0.03)  # ~30fps
```

### 状态控制逻辑

#### 暂停/继续逻辑

```python
def pause(self):
    with self.lock:
        self.is_paused = True

def resume(self):
    with self.lock:
        self.is_paused = False
```

#### 停止逻辑

```python
def stop(self):
    self.jump_out = True  # 设置退出标志
    self.quit()          # 退出线程
    self.wait()          # 等待线程结束
```

---

## 核心模块解析

### 1. 模型模块 (models/)

#### 1.1 YOLOv8架构

**Backbone (骨干网络)**:
```
输入图像 (640x640x3)
    ↓
Conv(64, 3, 2) → P1/2 (320x320x64)
    ↓
Conv(128, 3, 2) → P2/4 (160x160x128)
    ↓
C2f(128, 3) × 3
    ↓
Conv(256, 3, 2) → P3/8 (80x80x256)
    ↓
C2f(256, 6) × 6
    ↓
Conv(512, 3, 2) → P4/16 (40x40x512)
    ↓
C2f(512, 6) × 6
    ↓
Conv(1024, 3, 2) → P5/32 (20x20x1024)
    ↓
C2f(1024, 3) × 3
    ↓
SPPF(1024, 5)
```

**Neck (特征融合网络)**:
```
P5 → 上采样 → 与P4拼接 → C2f(512)
    ↓
上采样 → 与P3拼接 → C2f(256) → P3输出
    ↓
下采样 → 与P4拼接 → C2f(512) → P4输出
    ↓
下采样 → 与P5拼接 → C2f(1024) → P5输出
```

**Head (检测头)**:
```
P3, P4, P5 → Detect层
    ↓
输出: [batch, num_anchors, 5+num_classes]
    格式: [x, y, w, h, conf, cls1, cls2, ...]
```

#### 1.2 CBAM注意力机制

**Channel Attention (通道注意力)**:
```python
# models/conv.py - ChannelAttention
def forward(self, x):
    # 全局平均池化
    avg_out = self.avg_pool(x)
    # 全局最大池化
    max_out = self.max_pool(x)
    # MLP处理
    avg_out = self.fc(avg_out)
    max_out = self.fc(max_out)
    # 相加并激活
    out = self.act(avg_out + max_out)
    # 与输入相乘
    return x * out
```

**Spatial Attention (空间注意力)**:
```python
# models/conv.py - SpatialAttention
def forward(self, x):
    # 通道维度平均池化
    avg_out = torch.mean(x, dim=1, keepdim=True)
    # 通道维度最大池化
    max_out, _ = torch.max(x, dim=1, keepdim=True)
    # 拼接
    x = torch.cat([avg_out, max_out], dim=1)
    # 卷积处理
    x = self.conv(x)
    # 激活
    x = self.act(x)
    # 与输入相乘
    return x * input
```

**CBAM完整流程**:
```
输入特征图
    ↓
Channel Attention → 通道加权
    ↓
Spatial Attention → 空间加权
    ↓
输出特征图
```

### 2. 工具模块 (utils/)

#### 2.1 数据加载 (datasets.py)

**LoadImages类**:
- 支持图片和视频加载
- 自动处理不同格式
- 提供迭代器接口

**LoadWebcam类**:
- 摄像头实时捕获
- 帧率控制

**LoadStreams类**:
- 多路视频流支持
- RTSP流处理

#### 2.2 图像处理 (general.py)

**letterbox函数**:
- 保持宽高比的图像缩放
- 自动填充黑边

**non_max_suppression函数**:
- 非极大值抑制实现
- 过滤重复检测框

**scale_coords函数**:
- 坐标从模型输出尺寸缩放到原始图像尺寸

### 3. GUI模块 (main/)

#### 3.1 主界面 (innerface.py)

**UI组件**:
- `raw_video`: 显示原始视频流
- `out_video`: 显示检测结果
- `resultWidget`: 统计结果表格
- `progressBar`: 进度条
- `fps_label`: FPS显示

**信号连接**:
```python
# 检测线程 → UI更新
self.det_thread.send_raw.connect(lambda x: self.show_image(x, self.raw_video))
self.det_thread.send_img.connect(lambda x: self.show_image(x, self.out_video))
self.det_thread.send_statistic.connect(self._update_statistic_ui)
self.det_thread.send_fps.connect(lambda x: self.fps_label.setText(x))
self.det_thread.send_percent.connect(lambda x: self.progressBar.setValue(x))
```

#### 3.2 图像显示逻辑

```python
def show_image(self, img_src, label):
    # 1. 获取label尺寸
    label_width = label.width()
    label_height = label.height()
    
    # 2. 计算缩放比例
    h, w = img_src.shape[:2]
    scale = min(label_width / w, label_height / h)
    
    # 3. 大图像下采样优化
    if max(w, h) > 1920:
        img_src = cv2.resize(img_src, (int(w * 0.5), int(h * 0.5)))
    
    # 4. BGR转RGB
    img_rgb = cv2.cvtColor(img_src, cv2.COLOR_BGR2RGB)
    
    # 5. 转换为QImage
    qimg = QImage(img_rgb.data, img_rgb.shape[1], img_rgb.shape[0],
                  img_rgb.strides[0], QImage.Format_RGB888)
    
    # 6. 转换为QPixmap并缩放
    pixmap = QPixmap.fromImage(qimg)
    scaled_pixmap = pixmap.scaled(
        label.size() * 0.95,
        Qt.KeepAspectRatio,
        Qt.SmoothTransformation
    )
    
    # 7. 显示
    label.setPixmap(scaled_pixmap)
```

---

## 改进点说明

### 1. YOLOv8s改进

#### 1.1 CBAM注意力机制集成

**改进位置**:
- 在Bottleneck模块中集成CBAM
- 在C3模块中使用CBAMBottleneck

**改进效果**:
- 提升特征提取能力
- 增强对水下复杂环境的适应性
- 提高小目标检测精度

**代码位置**:
- `models/common.py`: CBAMBottleneck, C3CBAM类
- `models/conv.py`: ChannelAttention, SpatialAttention, CBAM类

#### 1.2 模型配置优化

**支持多种模型变体**:
- YOLOv8n: 最小模型，速度快
- YOLOv8s: 平衡模型（本项目使用）
- YOLOv8m: 中等模型
- YOLOv8l: 大模型
- YOLOv8x: 最大模型，精度高

### 2. 系统架构改进

#### 2.1 多线程设计

**优势**:
- UI响应不阻塞
- 检测任务独立运行
- 支持暂停/继续/停止

**实现**:
- 使用QThread创建检测线程
- 使用信号/槽机制进行线程间通信
- 使用锁机制保证线程安全

#### 2.2 内存管理优化

**优化措施**:
- 定时检查内存使用
- 超过阈值自动释放资源
- 及时释放模型和图像资源

**代码位置**:
```python
# main/innerface.py - memory_check()
def memory_check(self):
    process = psutil.Process(os.getpid())
    mem = process.memory_info().rss / 1024 / 1024  # MB
    if mem > 2048:  # 2GB阈值
        # 释放资源
        if self.det_thread.isRunning():
            self.det_thread.stop()
        torch.cuda.empty_cache()
```

### 3. 用户体验改进

#### 3.1 实时参数调整

- 置信度阈值实时调整
- IoU阈值实时调整
- 检测延迟控制

#### 3.2 结果可视化

- 双画面对比显示
- 实时统计表格
- FPS显示
- 进度条显示

#### 3.3 自动保存功能

- 检测结果自动保存
- 支持图片和视频保存
- 保存路径可配置

---

## 总结

本系统通过以下技术实现了高效的水下鱼类计数功能：

1. **深度学习**: 基于改进的YOLOv8s模型，集成CBAM注意力机制
2. **多线程架构**: 使用QThread实现检测任务与UI分离
3. **信号/槽机制**: 实现线程间安全通信
4. **多输入源支持**: 支持图片、视频、摄像头、RTSP流
5. **实时交互**: 参数实时调整，结果实时显示
6. **资源管理**: 内存监控和自动释放机制

系统具有良好的扩展性，可以方便地添加新功能或改进模型性能。

