# NYCU-SoC-2023
## 簡介
- **學校** : 國立陽明交通大學
- **開課單位** : 半導體碩
- **課程名稱** : 系統晶片設計
- **授課教授** : 賴瑾 教授
- **修課時間** : 2023年09月~2024年01月
- **最終成績** : A+

## 成績
||Lab1|Lab2|Lab3|Lab4-1|Lab4-2|Lab5|Lab#D|Lab6|Midterm|Final Project|Presentation|Study Journal|Soft Skill|Total|Grade|
|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
|占比|2%|4%|10%|4%|10%|8%|8%|15%|10%|30%|+3|+4|+3|101%+10|
|成績|98|96|97|92|96|95|97|92|82|89.54|0|+2|0|95.00|A+|

## 小組
|Team|Member 1|Member 2|Member 3|
|--|--|--|--|
|07|王語|何佳玲|黃鉦淳|

## 學習日誌(Journel Link)
本專案的詳細開發細節、除錯過程，均記錄於 HackMD：

👉 [NYCU-SoC 2023 Study Journal](https://hackmd.io/@pocper/BJzFTtSya)

## 實驗專案 (Labs)
### [part I] HLS 基礎與 FIR 設計
#### Lab 1: 流程入門
- 練習從 C++ HLS 建置 IP，並透過 Jupyter Notebook 在 PYNQ-Z2 上驗證

#### Lab 2: AXI 協議練習
- 學習兩種端口(AXI-Master 與 AXI-Stream)將資料從PS(Processing System)傳送至PL(Programable Logic)

#### Lab 3: FIR Filter 硬體化
- **規格**: 11-tap, 32-bit data width, 單一乘法器/加法器實現
- **效能**: 運算時間 640.35 [us]，約 64035 cycles (@100MHz)

---

### [Part II] Caravel SoC 系統整合
此階段重點在於將硬體 IP 掛載至 Caravel SoC 的 Wishbone 匯流排，並透過 RISC-V 韌體驅動

#### Lab 4: FIR SoC 整合 (Exmem & Caravel)
- **Lab 4-1 (Exmem)**: FIR 函數存放於外部 SRAM (mprjram)，CPU 透過 Wishbone 讀取指令執行
- **Lab 4-2 (Caravel)**: FIR 在 FPGA (User Project) 運行，韌體僅負責控制與資料搬運

#### Lab 6: 多任務工作負載 (Workload)
整合 FIR、矩陣相乘 (Matmul)、快速排序 (Qsort) 與 UART

<details>
<summary><b>點擊查看 UART ISR 中斷環回 (Loopback) 詳細流程</b></summary>

1. **偵測啟動**: `uart_rx.v` 監測 `mprj_io[5]` 下降緣
2. **中斷觸發**: 接收完成後透過 `user_project_wrapper` 對 CPU 發出 `user_irq`
3. **軟體響應**: CPU 進入 `trap_entry` 後調用 `isr()`，讀取數據並寫回發送暫存器
4. **環回輸出**: `uart_tx.v` 經由 `mprj_io[6]` 將資料傳回外部 Testbench
</details>

---

## 執行指南 (How to Run)

### 1. 環境準備
- **安裝工具鏈**: 下載並解壓 `xpack-riscv-none-elf-gcc` 與安裝 `iverilog`
- **設定環境變數 (PATH)**: 將工具鏈的 `bin` 資料夾路徑加入系統的 `PATH` 中，確保在任何路徑下都能調用編譯器
- **驗證安裝**: 在終端機輸入以下指令，若能顯示版本資訊即代表設定成功：
    ```bash
    riscv-none-elf-gcc -v
    iverilog -v
    ```
### 2. 模擬測試 (Simulation)
- Lab3
    ``` bash
    # simulation lab3-fir
    make -C caravel/lab3-fir
    ```
- Lab4
    ``` bash
    # simulation lab4-caravel_fir
    make -C caravel/lab4-caravel_fir

    # simulation lab4-exmem_fir
    make -C caravel/lab4-exmem_fir
    ```
- Lab6
    ``` bash
    # simulation lab6-integrate (fir + matmul + qsort + uart)
    make -C caravel/lab6-workload

    # simulation lab6-fir
    make -C caravel/lab6-workload sim_fir

    # simulation lab6-qsort
    make -C caravel/lab6-workload sim_qs

    # simulation lab6-matmul
    make -C caravel/lab6-workload sim_mm

    # simulation lab6-uart
    make -C caravel/lab6-workload sim_uart
    ```

### 3. 模擬合成與驗證(Synthesis & FPGA Verfication)
> [!IMPORTANT]
關於 Synthesis 檔案：由於硬體合成產生的專案目錄(Vivado Project)與編譯產物(Bitstream)體積較大，本 Repo 僅保留 原始 RTL 碼、韌體 C 程式碼 與 自動化腳本。讀者需依照下列步驟，於本地端重新產生合成環境

1. 重建 Vivado 專案環境：
從原始儲存庫複製基礎架構，並將本專案開發的 User Project RTL 覆蓋進去

    ``` bash
    git clone https://github.com/bol-edu/caravel-soc_fpga-lab.git
    cp -r caravel-soc_fpga-lab/lab-wlos_baseline/vivado caravel/lab6-workload/
    cp caravel/lab6-workload/rtl/user/*.v caravel/lab6-workload/vivado/vvd_srcs/caravel_soc/rtl/user/
    ```

2. 執行硬體合成 (Run Synthesis)：
使用提供的自動化腳本產生 Bitstream
    ``` bash
    chmod +x caravel/lab6-workload/vivado/run_vivado
    ./caravel/lab6-workload/vivado/run_vivado
    cp caravel/lab6-workload/counter_la_integrate.hex caravel/lab6-workload/vivado/jupyter_notebook
    ```

3. FPGA驗證 (FPGA Verification)：
請將 `caravel/lab6-workload/vivado/jupyter_notebook` 資料夾下的所有內容上傳至 PYNQ-Z2 的 Jupyter 環境執行：

   - 關鍵檔案清單：
     - 硬體位元流：*.bit 與 *.hwh(由 Vivado 合成產生)
     - 韌體程式：*.hex(counter_la_integrate.hex)
     - 驅動程式 (uartlite.py)：負責處理 PYNQ 與 FPGA 間的序列通訊邏輯
     - 驗證腳本 (*.ipynb)：主程式，負責載入 Overlay 並執行驗證測試

## 原始專案來源 (Original Project Sources)
本專案基於以下原始環境進行開發與整合。讀者若需查看課程提供的原始程式，可參考以下連結：

* **課程基礎練習 (Lab 1 & 2)**: [course-lab_1](https://github.com/bol-edu/course-lab_1) / [course-lab_2](https://github.com/bol-edu/course-lab_2)
* **SoC 核心框架 (Lab 3 ~ 6)**: [caravel-soc_fpga-lab](https://github.com/bol-edu/caravel-soc_fpga-lab)
