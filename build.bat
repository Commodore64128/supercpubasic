64tass -a src\scpubasic.asm -l target\scpubasic.lbl -L target\scpubasic.lst -o target\scpubasic
cd target
c1541 -attach scpubasic.d64 -delete scpubasic
c1541 -attach scpubasic.d64 -write scpubasic scpubasic
cd ..