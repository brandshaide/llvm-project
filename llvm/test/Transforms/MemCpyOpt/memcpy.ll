; RUN: opt < %s -basicaa -memcpyopt -dse -S | FileCheck %s

target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128"
target triple = "i686-apple-darwin9"

define void @test1({ x86_fp80, x86_fp80 }* sret  %agg.result, x86_fp80 %z.0, x86_fp80 %z.1) nounwind  {
entry:
	%tmp2 = alloca { x86_fp80, x86_fp80 }		; <{ x86_fp80, x86_fp80 }*> [#uses=1]
	%memtmp = alloca { x86_fp80, x86_fp80 }, align 16		; <{ x86_fp80, x86_fp80 }*> [#uses=2]
	%tmp5 = fsub x86_fp80 0xK80000000000000000000, %z.1		; <x86_fp80> [#uses=1]
	call void @ccoshl( { x86_fp80, x86_fp80 }* sret  %memtmp, x86_fp80 %tmp5, x86_fp80 %z.0 ) nounwind 
	%tmp219 = bitcast { x86_fp80, x86_fp80 }* %tmp2 to i8*		; <i8*> [#uses=2]
	%memtmp20 = bitcast { x86_fp80, x86_fp80 }* %memtmp to i8*		; <i8*> [#uses=1]
	call void @llvm.memcpy.i32( i8* %tmp219, i8* %memtmp20, i32 32, i32 16 )
	%agg.result21 = bitcast { x86_fp80, x86_fp80 }* %agg.result to i8*		; <i8*> [#uses=1]
	call void @llvm.memcpy.i32( i8* %agg.result21, i8* %tmp219, i32 32, i32 16 )

; Check that one of the memcpy's are removed.
;; FIXME: PR 8643 We should be able to eliminate the last memcpy here.

; CHECK: @test1
; CHECK: call void @ccoshl
; CHECK: call void @llvm.memcpy
; CHECK-NOT: llvm.memcpy
; CHECK: ret void
	ret void
}

declare void @ccoshl({ x86_fp80, x86_fp80 }* sret , x86_fp80, x86_fp80) nounwind 

declare void @llvm.memcpy.i32(i8*, i8*, i32, i32) nounwind 


; The intermediate alloca and one of the memcpy's should be eliminated, the
; other should be related with a memmove.
define void @test2(i8* %P, i8* %Q) nounwind  {
	%memtmp = alloca { x86_fp80, x86_fp80 }, align 16
	%R = bitcast { x86_fp80, x86_fp80 }* %memtmp to i8*
	call void @llvm.memcpy.i32( i8* %R, i8* %P, i32 32, i32 16 )
	call void @llvm.memcpy.i32( i8* %Q, i8* %R, i32 32, i32 16 )
        ret void
        
; CHECK: @test2
; CHECK-NEXT: call void @llvm.memmove{{.*}}(i8* %Q, i8* %P
; CHECK-NEXT: ret void
}




@x = external global { x86_fp80, x86_fp80 }

define void @test3({ x86_fp80, x86_fp80 }* noalias sret %agg.result) nounwind  {
	%x.0 = alloca { x86_fp80, x86_fp80 }
	%x.01 = bitcast { x86_fp80, x86_fp80 }* %x.0 to i8*
	call void @llvm.memcpy.i32( i8* %x.01, i8* bitcast ({ x86_fp80, x86_fp80 }* @x to i8*), i32 32, i32 16 )
	%agg.result2 = bitcast { x86_fp80, x86_fp80 }* %agg.result to i8*
	call void @llvm.memcpy.i32( i8* %agg.result2, i8* %x.01, i32 32, i32 16 )
	ret void
; CHECK: @test3
; CHECK-NEXT: %agg.result2 = bitcast 
; CHECK-NEXT: call void @llvm.memcpy
; CHECK-NEXT: ret void
}


; PR8644
define void @test4(i8 *%P) {
  %A = alloca {i32, i32}
  %a = bitcast {i32, i32}* %A to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* %a, i8* %P, i64 8, i32 4, i1 false)
  call void @test4a(i8* byval align 1 %a) 
  ret void
; CHECK: @test4
; CHECK-NEXT: call void @test4a(
}

declare void @test4a(i8* byval align 1)
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture, i8* nocapture, i64, i32, i1) nounwind
