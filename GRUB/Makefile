all: boot.iso test clean

boot.iso:
	@mkdir iso
	@cp stage2_eltorito iso
	@mkisofs -R -b stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -quiet -o $@ iso
	@rm iso/*
	@rmdir iso

test:
	@qemu-system-i386 -boot d -cdrom boot.iso

clean:
	@rm boot.iso
