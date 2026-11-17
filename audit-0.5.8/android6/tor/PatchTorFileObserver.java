// YomiHub 0.5.6.1 A6: vá tor-android 0.4.9.13 cho Android 6.0.
// TorService$1$1 (lớp con FileObserver) gọi super(File) = FileObserver.<init>(Ljava/io/File;)V (API 29)
// -> NoSuchMethodError trên API < 29. Đổi thành File.getAbsolutePath() + FileObserver.<init>(Ljava/lang/String;)V
// (có từ API 1, cùng ý nghĩa). Dùng ASM 9.9.  java -cp asm-9.9.jar PatchTorFileObserver.java in.class out.class
import org.objectweb.asm.*;
import java.nio.file.*;

public class PatchTorFileObserver {
    public static void main(String[] a) throws Exception {
        ClassReader cr = new ClassReader(Files.readAllBytes(Paths.get(a[0])));
        ClassWriter cw = new ClassWriter(0);
        int[] hits = {0};
        cr.accept(new ClassVisitor(Opcodes.ASM9, cw) {
            @Override public MethodVisitor visitMethod(int acc, String name, String desc, String sig, String[] ex) {
                MethodVisitor mv = super.visitMethod(acc, name, desc, sig, ex);
                return new MethodVisitor(Opcodes.ASM9, mv) {
                    @Override public void visitMethodInsn(int op, String owner, String n, String d, boolean itf) {
                        if (op == Opcodes.INVOKESPECIAL && owner.equals("android/os/FileObserver") && n.equals("<init>") && d.equals("(Ljava/io/File;)V")) {
                            super.visitMethodInsn(Opcodes.INVOKEVIRTUAL, "java/io/File", "getAbsolutePath", "()Ljava/lang/String;", false);
                            super.visitMethodInsn(op, owner, n, "(Ljava/lang/String;)V", false);
                            hits[0]++;
                        } else super.visitMethodInsn(op, owner, n, d, itf);
                    }
                };
            }
        }, 0);
        if (hits[0] != 1) throw new IllegalStateException("so cho va = " + hits[0] + " (can 1)");
        Files.write(Paths.get(a[1]), cw.toByteArray());
        System.out.println("patched " + a[0] + " -> " + a[1]);
    }
}
