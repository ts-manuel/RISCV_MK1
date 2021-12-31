# RISC-V MK1
![Board_3D_TOP.png](inkscape/cpu_diagram.png)


<!-- TABLE OF CONTENTS -->
<details open="open">
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#installation-newlib">Installation (Newlib)</a></li>
  </ol>
</details>


<!-- ABOUT THE PROJECT -->
## About The Project
Multicycle RISC-V CPU implemented in VHDL.


<!-- COMPILING GCC -->
### Installation (Newlib)

https://github.com/riscv-collab/riscv-gnu-toolchain\
To build the cross-compiler, pick an install path.\
If you choose, say, `/opt/riscv`, then add `/opt/riscv/bin` to your `PATH` now.\
Then, simply run the following command:

    git clone https://github.com/riscv/riscv-gnu-toolchain
    cd riscv-gnu-toolchain/
    ./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi=ilp32
    sudo make