// YomiHub 0.5.6.1 A6: wireguard-android tunnel 1.0.20260102 (GoBackend) dùng java.util.concurrent.CompletableFuture
// (API 24, desugar_jdk_libs không hỗ trợ) -> trên Android 6 lớp GoBackend hỏng (NoClassDefFoundError), WARP/WireGuard làm app thoát.
// Đổi mọi tham chiếu CompletableFuture trong các lớp GoBackend* sang com.kodjodevf.mangayomi.YhA6Future (YhA6Future.kt).
//   java -cp asm-9.9.jar:asm-commons-9.9.jar RemapCompletableFuture.java <thư_mục_lớp>
import org.objectweb.asm.*;
import org.objectweb.asm.commons.*;
import java.nio.file.*;
import java.util.*;

public class RemapCompletableFuture {
    public static void main(String[] a) throws Exception {
        Remapper rm = new SimpleRemapper(Map.of("java/util/concurrent/CompletableFuture", "com/kodjodevf/mangayomi/YhA6Future"));
        int n = 0;
        try (var s = Files.walk(Paths.get(a[0]))) {
            for (Path p : (Iterable<Path>) s.filter(x -> x.toString().endsWith(".class"))::iterator) {
                byte[] b = Files.readAllBytes(p);
                if (!new String(b, "ISO-8859-1").contains("java/util/concurrent/CompletableFuture")) continue;
                ClassReader cr = new ClassReader(b);
                ClassWriter cw = new ClassWriter(0);
                cr.accept(new ClassRemapper(cw, rm), 0);
                Files.write(p, cw.toByteArray());
                System.out.println("remap " + p); n++;
            }
        }
        if (n == 0) throw new IllegalStateException("khong co lop nao dung CompletableFuture");
    }
}
