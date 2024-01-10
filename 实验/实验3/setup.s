!
!	setup.s		(C) 1991 Linus Torvalds
!
! setup.s is responsible for getting the system data from the BIOS,
! and putting them into the appropriate places in system memory.
! both setup.s and system has been loaded by the bootblock.
!
! This code asks the bios for memory/disk/other parameters, and
! puts them in a "safe" place: 0x90000-0x901FF, ie where the
! boot-block used to be. It is then up to the protected mode
! system to read them from there before the area is overwritten
! for buffer-blocks.
!

! NOTE! These had better be the same as in bootsect.s!

INITSEG  = 0x9000	! we move boot here - out of the way

entry start
start:
! Print some inane message

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#28
	mov	bx,#0x0006
	mov	bp,#msg2
	mov	ax,cs
	mov	es,ax
	mov	ax,#0x1301
	int	0x10
	
! ok, the read went well so we get current cursor position and save it for
! posterity.

	mov	ax,#INITSEG	! this is done in bootsect already, but...
	mov	ds,ax
	mov	ah,#0x03	! read cursor pos
	xor	bh,bh
	int	0x10		! save it in known place, con_init fetches
	mov	[0],dx		! it from 0x90000.

	
! Get memory size (extended mem, kB)

	mov	ah,#0x88
	int	0x15
	mov	[2],ax

! Get video-card data:

	mov	ah,#0x0f
	int	0x10
	mov	[4],bx		! bh = display page
	mov	[6],ax		! al = video mode, ah = window width

	
!从0x41处拷贝16个字节（磁盘参数表）
	mov    ax,#0x0000
	mov    ds,ax
	lds    si,[4*0x41]
	mov    ax,#INITSEG
	mov    es,ax
	mov    di,#0x0004
	mov    cx,#0x10
	rep            !重复16次
	movsb

! Reset rigisters
    	mov	ax, cs
    	mov	es, ax
    	mov	ax, #INITSEG
    	mov	ds, ax
    	mov	ss, ax
	
! print cursur position
	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#18
	mov	bx,#0x0006
	mov	bp,#msg_cursor
	mov	ax,#0x1301
	int	0x10
	mov	dx,[0]		! cursor position
	call	print_hex
	
! print memory info
	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#14
	mov	bx,#0x0006
	mov	bp,#msg_mem
	mov	ax,#0x1301
	int	0x10
! print value
	mov	dx, [2]
	call	print_hex
! print kb
	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#2
	mov	bx,#0x0006
	mov	bp,#msg_mem2
	mov	ax,#0x1301
	int	0x10
	
! print video-card info
	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#15
	mov	bx,#0x0006
	mov	bp,#msg_vc
	mov	ax,#0x1301
	int	0x10
! print value
	mov	dx, [4]
	call	print_hex
! print second info
	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#30
	mov	bx,#0x0006
	mov	bp,#msg_vc2
	mov	ax,#0x1301
	int	0x10
! print value
	mov	dx, [6]
	call	print_hex
	
! print cylinders
	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#12
	mov	bx,#0x0006
	mov	bp,#msg_cy
	mov	ax,#0x1301
	int	0x10
	mov	dx, [0x4]
	call	print_hex
! print headers
	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#10
	mov	bx,#0x0006
	mov	bp,#msg_hd
	mov	ax,#0x1301
	int	0x10
	mov	dx, [0x4+0x2]
	call	print_hex
! print sectors
	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#10
	mov	bx,#0x0006
	mov	bp,#msg_sec
	mov	ax,#0x1301
	int	0x10
	mov	dx, [0x4+0xe]
	call	print_hex
	call	print_nl
	
loooop:
	jmp loooop			! waiting..


!以16进制方式打印栈顶的16位数
print_hex:
    	mov    cx,#4         ! 4个十六进制数字
!    	mov    dx,(bp)       ! 将(bp)所指的值放入dx中，如果bp是指向栈顶的话
! we have directly put the values in dx so we don't need this
print_digit:
    	rol    dx,#4         ! 循环以使低4比特用上 !! 取dx的高4比特移到低4比特处。
    	mov    ax,#0xe0f     ! ah = 请求的功能值，al = 半字节(4个比特)掩码。
    	and    al,dl         ! 取dl的低4比特值。
    	add    al,#0x30      ! 给al数字加上十六进制0x30
    	cmp    al,#0x3a
    	jl     outp          ! 是一个不大于十的数字
    	add    al,#0x07      ! 是a～f，要多加7
outp:
    	int    0x10
    	loop   print_digit
    	ret
!打印回车换行
print_nl:
    	mov    ax,#0xe0d   ! CR
    	int    0x10
    	mov    al,#0xa     ! LF
    	int    0x10
    	ret

msg2:
	.byte 13,10
	.ascii "Now we are in SETUP..."
	.byte 13,10,13,10
msg_cursor:
    .byte 13, 10
    .ascii "Cursor Position:"
msg_mem:
    .byte 13,10
    .ascii "Memory Size:"
msg_mem2:
    .ascii "KB"
msg_vc:
    .byte 13,10
    .ascii "Display Page:"
msg_vc2:
    .byte 13,10
    .ascii "Video Mode and Window Width:"
msg_cy:
    .byte 13,10
    .ascii "Cylinders:"
msg_hd:
    .byte 13,10
    .ascii "Headers:"
msg_sec:
    .byte 13,10
    .ascii "Sectors:"


.org 510
boot_flag:
    .word 0xAA55
