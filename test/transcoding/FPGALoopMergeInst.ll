; LLVM IR for the test can be generated by SYCL Clang Compiler -
; see https://github.com/intel/llvm
; SYCL source code can be found below:

; void foo() {
;   int i = 0;
;   int m = 42;

;  [[intelfpga::ivdep]]
;   while (i < m) {
;     if (i % 2) {
;       ++i;
;       continue;
;     }
;   }

;   i = 0;
;   [[intelfpga::ii(2)]]
;   while (i < m) {
;     if (i % 3) {
;       ++i;
;       continue;
;     }
;   }

;   i = 0;
;   [[intelfpga::max_concurrency(4)]]
;   while (i < m) {
;     if (i % 5) {
;       ++i;
;       continue;
;     }
;   }

;   i = 0;
;   [[intelfpga::ivdep(2)]]
;   while (true) {
;     if (i % 2) {
;       ++i;
;       continue;
;     }
;     if (i % 2 != 0)
;       break;
;   }
; }

; void loop_pipelining() {
;   int a[10];
;   [[intelfpga::disable_loop_pipelining]]
;   for (int i = 0; i != 10; ++i)
;     a[i] = 0;
; }

; void loop_coalesce() {
;   int i = 0, m = 42;
;   [[intelfpga::loop_coalesce(4)]]
;   while (i < m) {
;     if (i % 2) {
;       ++i;
;       continue;
;     }
;   }
;   i = 0;
;   [[intelfpga::loop_coalesce]]
;   while (i < m) {
;     if (i % 3) {
;       ++i;
;       continue;
;     }
;   }
; }

; void max_interleaving() {
;   int a[10];
;   [[intelfpga::max_interleaving(3)]]
;   for (int i = 0; i != 10; ++i)
;     a[i] = 0;
; }

; void speculated_iterations() {
;   int a[10];
;   [[intelfpga::speculated_iterations(4)]]
;   for (int i = 0; i != 10; ++i)
;     a[i] = 0;
; }

; TODO: This source code will result in different LLVM IR after
; rev [a47242e4b2c1c9] of https://github.com/intel/llvm (the
; [[intelfpga::ivdep]] attribute will be represented otherwise).
; It's worth factoring out the old representation's translation:
; (!"llvm.loop.ivdep.*" <-> LoopControlDependency*Mask)
; into a separate test file

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-ext=+all -o %t.spv
; RUN: llvm-spirv %t.spv --to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: 2 Capability FPGALoopControlsINTEL
; CHECK-SPIRV: 9 Extension "SPV_INTEL_fpga_loop_controls"

; CHECK-SPIRV: 6 Name [[FOR:[0-9]+]] "while.body20"

; ModuleID = 'FPGALoopMergeInst.cpp'
source_filename = "FPGALoopMergeInst.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-linux-sycldevice"

%"class._ZTSZ4mainE3$_0.anon" = type { i8 }

define dso_local spir_kernel void @_ZTSZ4mainE15kernel_function() #0 !kernel_arg_addr_space !4 !kernel_arg_access_qual !4 !kernel_arg_type !4 !kernel_arg_base_type !4 !kernel_arg_type_qual !4 {
entry:
  %0 = alloca %"class._ZTSZ4mainE3$_0.anon", align 1
  %1 = bitcast %"class._ZTSZ4mainE3$_0.anon"* %0 to i8*
  call void @llvm.lifetime.start.p0i8(i64 1, i8* %1) #4
  %2 = addrspacecast %"class._ZTSZ4mainE3$_0.anon"* %0 to %"class._ZTSZ4mainE3$_0.anon" addrspace(4)*
  call spir_func void @"_ZZ4mainENK3$_0clEv"(%"class._ZTSZ4mainE3$_0.anon" addrspace(4)* %2)
  %3 = bitcast %"class._ZTSZ4mainE3$_0.anon"* %0 to i8*
  call void @llvm.lifetime.end.p0i8(i64 1, i8* %3) #4
  ret void
}

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #1

; Function Attrs: inlinehint nounwind
define internal spir_func void @"_ZZ4mainENK3$_0clEv"(%"class._ZTSZ4mainE3$_0.anon" addrspace(4)* %this) #2 align 2 {
entry:
  %this.addr = alloca %"class._ZTSZ4mainE3$_0.anon" addrspace(4)*, align 8
    store %"class._ZTSZ4mainE3$_0.anon" addrspace(4)* %this, %"class._ZTSZ4mainE3$_0.anon" addrspace(4)** %this.addr, align 8, !tbaa !5
  %this1 = load %"class._ZTSZ4mainE3$_0.anon" addrspace(4)*, %"class._ZTSZ4mainE3$_0.anon" addrspace(4)** %this.addr, align 8
  call spir_func void @_Z3foov()
  ret void
}

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.lifetime.end.p0i8(i64 immarg, i8* nocapture) #1

; Function Attrs: nounwind
define dso_local spir_func void @_Z3foov() #3 {
entry:
  %i = alloca i32, align 4
  %m = alloca i32, align 4
  %0 = bitcast i32* %i to i8*
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %0) #4
  store i32 0, i32* %i, align 4, !tbaa !9
  %1 = bitcast i32* %m to i8*
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %1) #4
  store i32 42, i32* %m, align 4, !tbaa !9
  br label %while.cond
; CHECK-SPIRV: 4 LoopMerge {{[0-9]+}} {{[0-9]+}} 4
; CHECK-SPIRV-NEXT: 4 BranchConditional {{[0-9]+}} {{[0-9]+}} {{[0-9]+}}
while.cond:                                       ; preds = %if.end, %if.then, %entry
  %2 = load i32, i32* %i, align 4, !tbaa !9
  %3 = load i32, i32* %m, align 4, !tbaa !9
  %cmp = icmp slt i32 %2, %3
  br i1 %cmp, label %while.body, label %while.end

while.body:                                       ; preds = %while.cond
  %4 = load i32, i32* %i, align 4, !tbaa !9
  %rem = srem i32 %4, 2
  %tobool = icmp ne i32 %rem, 0
  br i1 %tobool, label %if.then, label %if.end

if.then:                                          ; preds = %while.body
  %5 = load i32, i32* %i, align 4, !tbaa !9
  %inc = add nsw i32 %5, 1
  store i32 %inc, i32* %i, align 4, !tbaa !9
  br label %while.cond, !llvm.loop !11

if.end:                                           ; preds = %while.body
  br label %while.cond, !llvm.loop !11

while.end:                                        ; preds = %while.cond
  br label %while.cond1
; Per SPIR-V spec extension INTEL/SPV_INTEL_fpga_loop_controls,
; LoopControlInitiationIntervalINTEL = 0x10000 (65536)
; CHECK-SPIRV: 5 LoopMerge {{[0-9]+}} {{[0-9]+}} 65536 2
; CHECK-SPIRV-NEXT: 4 BranchConditional {{[0-9]+}} {{[0-9]+}} {{[0-9]+}}
while.cond1:                                      ; preds = %if.end8, %if.then6, %while.end
  %6 = load i32, i32* %i, align 4, !tbaa !9
  %7 = load i32, i32* %m, align 4, !tbaa !9
  %cmp2 = icmp slt i32 %6, %7
  br i1 %cmp2, label %while.body3, label %while.end9

while.body3:                                      ; preds = %while.cond1
  %8 = load i32, i32* %i, align 4, !tbaa !9
  %rem4 = srem i32 %8, 3
  %tobool5 = icmp ne i32 %rem4, 0
  br i1 %tobool5, label %if.then6, label %if.end8

if.then6:                                         ; preds = %while.body3
  %9 = load i32, i32* %i, align 4, !tbaa !9
  %inc7 = add nsw i32 %9, 1
  store i32 %inc7, i32* %i, align 4, !tbaa !9
  br label %while.cond1, !llvm.loop !13

if.end8:                                          ; preds = %while.body3
  br label %while.cond1, !llvm.loop !13

while.end9:                                       ; preds = %while.cond1
  br label %while.cond10
; Per SPIR-V spec extension INTEL/SPV_INTEL_fpga_loop_controls,
; LoopControlMaxConcurrencyINTEL = 0x20000 (131072)
; CHECK-SPIRV: 5 LoopMerge {{[0-9]+}} {{[0-9]+}} 131072 4
; CHECK-SPIRV-NEXT: 4 BranchConditional {{[0-9]+}} {{[0-9]+}} {{[0-9]+}}
while.cond10:                                     ; preds = %if.end17, %if.then15, %while.end9
  %10 = load i32, i32* %i, align 4, !tbaa !9
  %11 = load i32, i32* %m, align 4, !tbaa !9
  %cmp11 = icmp slt i32 %10, %11
  br i1 %cmp11, label %while.body12, label %while.end18

while.body12:                                     ; preds = %while.cond10
  %12 = load i32, i32* %i, align 4, !tbaa !9
  %rem13 = srem i32 %12, 5
  %tobool14 = icmp ne i32 %rem13, 0
  br i1 %tobool14, label %if.then15, label %if.end17

if.then15:                                        ; preds = %while.body12
  %13 = load i32, i32* %i, align 4, !tbaa !9
  %inc16 = add nsw i32 %13, 1
  store i32 %inc16, i32* %i, align 4, !tbaa !9
  br label %while.cond10, !llvm.loop !15

if.end17:                                         ; preds = %while.body12
  br label %while.cond10, !llvm.loop !15

while.end18:                                      ; preds = %while.cond10
  store i32 0, i32* %i, align 4, !tbaa !9
  br label %while.cond19
; CHECK-SPIRV: 3 LoopControlINTEL 8 2
; CHECK-SPIRV-NEXT: 2 Branch [[FOR]]
while.cond19:                                     ; preds = %if.end29, %if.then23, %while.end18
  br label %while.body20

while.body20:                                     ; preds = %while.cond19
  %14 = load i32, i32* %i, align 4, !tbaa !9
  %rem21 = srem i32 %14, 2
  %tobool22 = icmp ne i32 %rem21, 0
  br i1 %tobool22, label %if.then23, label %if.end25

if.then23:                                        ; preds = %while.body20
  %15 = load i32, i32* %i, align 4, !tbaa !9
  %inc24 = add nsw i32 %15, 1
  store i32 %inc24, i32* %i, align 4, !tbaa !9
  br label %while.cond19, !llvm.loop !17

if.end25:                                         ; preds = %while.body20
  %16 = load i32, i32* %i, align 4, !tbaa !9
  %rem26 = srem i32 %16, 2
  %cmp27 = icmp ne i32 %rem26, 0
  br i1 %cmp27, label %if.then28, label %if.end29

if.then28:                                        ; preds = %if.end25
  br label %while.end30

if.end29:                                         ; preds = %if.end25
  br label %while.cond19, !llvm.loop !17

while.end30:                                      ; preds = %if.then28
  %17 = bitcast i32* %m to i8*
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %17) #4
  %18 = bitcast i32* %i to i8*
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %18) #4
  ret void
}

; Function Attrs: noinline nounwind optnone
define spir_func void @loop_pipelining() #3 {
entry:
  %a = alloca [10 x i32], align 4
  %i = alloca i32, align 4
  store i32 0, i32* %i, align 4
  br label %for.cond

; Per SPIR-V spec, LoopControlPipelineEnableINTEL = 0x80000 (524288)
; CHECK-SPIRV: 5 LoopMerge {{[0-9]+}} {{[0-9]+}} 524288 1
; CHECK-SPIRV-NEXT: 4 BranchConditional {{[0-9]+}} {{[0-9]+}} {{[0-9]+}}
; CHECK-SPIRV-NEGATIVE-NOT: 5 LoopMerge {{[0-9]+}} {{[0-9]+}} 524288 1
for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, i32* %i, align 4
  %cmp = icmp ne i32 %0, 10
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i32, i32* %i, align 4
  %idxprom = sext i32 %1 to i64
  %arrayidx = getelementptr inbounds [10 x i32], [10 x i32]* %a, i64 0, i64 %idxprom
  store i32 0, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %2 = load i32, i32* %i, align 4
  %inc = add nsw i32 %2, 1
  store i32 %inc, i32* %i, align 4
  br label %for.cond, !llvm.loop !19

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: noinline nounwind optnone
define spir_func void @loop_coalesce() #3 {
entry:
  %i = alloca i32, align 4
  %m = alloca i32, align 4
  store i32 0, i32* %i, align 4
  store i32 42, i32* %m, align 4
  br label %while.cond

; Per SPIR-V spec, LoopControlLoopCoalesceINTEL = 0x100000 (1048576)
; CHECK-SPIRV: 5 LoopMerge {{[0-9]+}} {{[0-9]+}} 1048576 4
; CHECK-SPIRV-NEXT: 4 BranchConditional {{[0-9]+}} {{[0-9]+}} {{[0-9]+}}
; CHECK-SPIRV-NEGATIVE-NOT: 5 LoopMerge {{[0-9]+}} {{[0-9]+}} 1048576 4
while.cond:                                       ; preds = %if.end, %if.then, %entry
  %0 = load i32, i32* %i, align 4
  %1 = load i32, i32* %m, align 4
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %while.body, label %while.end

while.body:                                       ; preds = %while.cond
  %2 = load i32, i32* %i, align 4
  %rem = srem i32 %2, 2
  %tobool = icmp ne i32 %rem, 0
  br i1 %tobool, label %if.then, label %if.end

if.then:                                          ; preds = %while.body
  %3 = load i32, i32* %i, align 4
  %inc = add nsw i32 %3, 1
  store i32 %inc, i32* %i, align 4
  br label %while.cond, !llvm.loop !21

if.end:                                           ; preds = %while.body
  br label %while.cond, !llvm.loop !21

while.end:                                        ; preds = %while.cond
  store i32 0, i32* %i, align 4
  br label %while.cond1

; Per SPIR-V spec, LoopControlLoopCoalesceINTEL = 0x100000 (1048576)
; CHECK-SPIRV: 4 LoopMerge {{[0-9]+}} {{[0-9]+}} 1048576
; CHECK-SPIRV-NEXT: 4 BranchConditional {{[0-9]+}} {{[0-9]+}} {{[0-9]+}}
; CHECK-SPIRV-NEGATIVE-NOT: 4 LoopMerge {{[0-9]+}} {{[0-9]+}} 1048576
while.cond1:                                      ; preds = %if.end8, %if.then6, %while.end
  %4 = load i32, i32* %i, align 4
  %5 = load i32, i32* %m, align 4
  %cmp2 = icmp slt i32 %4, %5
  br i1 %cmp2, label %while.body3, label %while.end9

while.body3:                                      ; preds = %while.cond1
  %6 = load i32, i32* %i, align 4
  %rem4 = srem i32 %6, 3
  %tobool5 = icmp ne i32 %rem4, 0
  br i1 %tobool5, label %if.then6, label %if.end8

if.then6:                                         ; preds = %while.body3
  %7 = load i32, i32* %i, align 4
  %inc7 = add nsw i32 %7, 1
  store i32 %inc7, i32* %i, align 4
  br label %while.cond1, !llvm.loop !23

if.end8:                                          ; preds = %while.body3
  br label %while.cond1, !llvm.loop !23

while.end9:                                       ; preds = %while.cond1
  ret void
}

; Function Attrs: noinline nounwind optnone
define spir_func void @max_interleaving() #3 {
entry:
  %a = alloca [10 x i32], align 4
  %i = alloca i32, align 4
  store i32 0, i32* %i, align 4
  br label %for.cond

; Per SPIR-V spec, LoopControlMaxInterleavingINTEL = 0x200000 (2097152)
; CHECK-SPIRV: 5 LoopMerge {{[0-9]+}} {{[0-9]+}} 2097152 3
; CHECK-SPIRV-NEXT: 4 BranchConditional {{[0-9]+}} {{[0-9]+}} {{[0-9]+}}
; CHECK-SPIRV-NEGATIVE-NOT: 5 LoopMerge {{[0-9]+}} {{[0-9]+}} 2097152 3
for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, i32* %i, align 4
  %cmp = icmp ne i32 %0, 10
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i32, i32* %i, align 4
  %idxprom = sext i32 %1 to i64
  %arrayidx = getelementptr inbounds [10 x i32], [10 x i32]* %a, i64 0, i64 %idxprom
  store i32 0, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %2 = load i32, i32* %i, align 4
  %inc = add nsw i32 %2, 1
  store i32 %inc, i32* %i, align 4
  br label %for.cond, !llvm.loop !25

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: noinline nounwind optnone
define spir_func void @speculated_iterations() #3 {
entry:
  %a = alloca [10 x i32], align 4
  %i = alloca i32, align 4
  store i32 0, i32* %i, align 4
  br label %for.cond

; Per SPIR-V spec, LoopControlSpeculatedIterationsINTEL = 0x400000 (4194304)
; CHECK-SPIRV: 5 LoopMerge {{[0-9]+}} {{[0-9]+}} 4194304 4
; CHECK-SPIRV-NEXT: 4 BranchConditional {{[0-9]+}} {{[0-9]+}} {{[0-9]+}}
; CHECK-SPIRV-NEGATIVE-NOT: 5 LoopMerge {{[0-9]+}} {{[0-9]+}} 4194304 4
for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, i32* %i, align 4
  %cmp = icmp ne i32 %0, 10
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i32, i32* %i, align 4
  %idxprom = sext i32 %1 to i64
  %arrayidx = getelementptr inbounds [10 x i32], [10 x i32]* %a, i64 0, i64 %idxprom
  store i32 0, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %2 = load i32, i32* %i, align 4
  %inc = add nsw i32 %2, 1
  store i32 %inc, i32* %i, align 4
  br label %for.cond, !llvm.loop !27

for.end:                                          ; preds = %for.cond
  ret void
}

attributes #0 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "sycl-module-id"="FPGALoopMergeInst.cpp" "uniform-work-group-size"="true" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { argmemonly nounwind willreturn }
attributes #2 = { inlinehint nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0}
!opencl.spir.version = !{!1}
!spirv.Source = !{!2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{i32 4, i32 100000}
!3 = !{!"clang version 10.0.0"}
!4 = !{}
!5 = !{!6, !6, i64 0}
!6 = !{!"any pointer", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C++ TBAA"}
!9 = !{!10, !10, i64 0}
!10 = !{!"int", !7, i64 0}
!11 = distinct !{!11, !12}
!12 = !{!"llvm.loop.ivdep.enable"}
!13 = distinct !{!13, !14}
!14 = !{!"llvm.loop.ii.count", i32 2}
!15 = distinct !{!15, !16}
!16 = !{!"llvm.loop.max_concurrency.count", i32 4}
!17 = distinct !{!17, !18}
!18 = !{!"llvm.loop.ivdep.safelen", i32 2}
!19 = distinct !{!19, !20}
!20 = !{!"llvm.loop.intel.pipelining.enable", i32 1}
!21 = distinct !{!21, !22}
!22 = !{!"llvm.loop.coalesce.count", i32 4}
!23 = distinct !{!23, !24}
!24 = !{!"llvm.loop.coalesce.enable"}
!25 = distinct !{!25, !26}
!26 = !{!"llvm.loop.max_interleaving.count", i32 3}
!27 = distinct !{!27, !28}
!28 = !{!"llvm.loop.intel.speculated.iterations.count", i32 4}

; CHECK-LLVM: br label %while.cond, !llvm.loop ![[MD_A:[0-9]+]]
; CHECK-LLVM: br label %while.cond{{[0-9]+}}, !llvm.loop ![[MD_B:[0-9]+]]
; CHECK-LLVM: br label %while.cond{{[0-9]+}}, !llvm.loop ![[MD_C:[0-9]+]]
; CHECK-LLVM: br label %while.cond{{[0-9]+}}, !llvm.loop ![[MD_D:[0-9]+]]
; CHECK-LLVM: br label %for.cond{{[0-9]*}}, !llvm.loop ![[MD_E:[0-9]+]]
; CHECK-LLVM: br label %while.cond{{[0-9]*}}, !llvm.loop ![[MD_F:[0-9]+]]
; CHECK-LLVM: br label %while.cond{{[0-9]+}}, !llvm.loop ![[MD_G:[0-9]+]]
; CHECK-LLVM: br label %for.cond{{[0-9]*}}, !llvm.loop ![[MD_H:[0-9]+]]
; CHECK-LLVM: br label %for.cond{{[0-9]*}}, !llvm.loop ![[MD_I:[0-9]+]]

; CHECK-LLVM: ![[MD_A]] = distinct !{![[MD_A]], ![[MD_ivdep_enable:[0-9]+]]}
; CHECK-LLVM: ![[MD_ivdep_enable]] = !{!"llvm.loop.ivdep.enable"}
; CHECK-LLVM: ![[MD_B]] = distinct !{![[MD_B]], ![[MD_ii:[0-9]+]]}
; CHECK-LLVM: ![[MD_ii]] = !{!"llvm.loop.ii.count", i32 2}
; CHECK-LLVM: ![[MD_C]] = distinct !{![[MD_C]], ![[MD_max_conc:[0-9]+]]}
; CHECK-LLVM: ![[MD_max_conc]] = !{!"llvm.loop.max_concurrency.count", i32 4}
; CHECK-LLVM: ![[MD_D]] = distinct !{![[MD_D]], ![[MD_ivdep:[0-9]+]]}
; CHECK-LLVM: ![[MD_ivdep]] = !{!"llvm.loop.ivdep.safelen", i32 2}
; CHECK-LLVM: ![[MD_E]] = distinct !{![[MD_E]], ![[MD_pipelining:[0-9]+]]}
; CHECK-LLVM: ![[MD_pipelining]] = !{!"llvm.loop.intel.pipelining.enable", i32 1}
; CHECK-LLVM: ![[MD_F]] = distinct !{![[MD_F]], ![[MD_loop_coalesce_count:[0-9]+]]}
; CHECK-LLVM: ![[MD_loop_coalesce_count]] = !{!"llvm.loop.coalesce.count", i32 4}
; CHECK-LLVM: ![[MD_G]] = distinct !{![[MD_G]], ![[MD_loop_coalesce:[0-9]+]]}
; CHECK-LLVM: ![[MD_loop_coalesce]] = !{![[MD_loop_coalesce_enable:[0-9]+]]}
; CHECK-LLVM: ![[MD_loop_coalesce_enable]] = !{!"llvm.loop.coalesce.enable"}
; CHECK-LLVM: ![[MD_H]] = distinct !{![[MD_H]], ![[MD_max_interleaving:[0-9]+]]}
; CHECK-LLVM: ![[MD_max_interleaving]] = !{!"llvm.loop.max_interleaving.count", i32 3}
; CHECK-LLVM: ![[MD_I]] = distinct !{![[MD_I]], ![[MD_spec_iterations:[0-9]+]]}
; CHECK-LLVM: ![[MD_spec_iterations]] = !{!"llvm.loop.intel.speculated.iterations.count", i32 4}
