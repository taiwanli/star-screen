package com.starscreen.jar

import android.content.Context
import dalvik.system.DexClassLoader
import java.io.File
import java.security.MessageDigest

/// jar 蜘蛛执行核心（TVBox Spider 契约）。由 MainActivity 的 MethodChannel 调用。
class JarSpiderRuntime(private val context: Context) {

    private var classLoader: DexClassLoader? = null
    private var spider: Any? = null
    private var loadedJar: String? = null

    fun load(path: String, className: String, md5: String?) {
        val file = File(path)
        if (!file.exists()) error("jar 不存在: $path")
        if (!md5.isNullOrBlank()) {
            val actual = md5Of(file)
            if (!actual.equals(md5, ignoreCase = true)) error("jar md5 不匹配")
        }
        if (loadedJar == path && spider != null) return
        val opt = context.codeCacheDir.absolutePath
        val cl = DexClassLoader(path, opt, null, context.classLoader)
        val clazz = findClass(cl, className)
        spider = instantiate(clazz, context)
        classLoader = cl
        loadedJar = path
    }

    fun call(method: String, args: Map<String, Any?>): String {
        val sp = spider ?: error("jar 未加载")
        val ret = when (method) {
            "home" -> {
                val m = findMethod(sp, "homeContent", Boolean::class.javaPrimitiveType!!)
                m.invoke(sp, args["filter"] == true)
            }
            "homeVod" -> findMethod(sp, "homeVideoContent").invoke(sp)
            "category" -> findMethod(
                sp, "categoryContent",
                String::class.java, String::class.java,
                Boolean::class.javaPrimitiveType!!, String::class.java,
            ).invoke(
                sp,
                args["tid"]?.toString() ?: "",
                args["pg"]?.toString() ?: "1",
                args["filter"] != false,
                args["extend"]?.toString() ?: "",
            )
            "detail" -> {
                val ids = (args["ids"] as? List<*>)
                    ?.map { it.toString() }
                    ?: listOf(args["id"]?.toString() ?: "")
                findMethod(sp, "detailContent", List::class.java).invoke(sp, ids)
            }
            "player" -> {
                val vip = (args["vipFlags"] as? List<*>)
                    ?.map { it.toString() } ?: emptyList()
                findMethod(
                    sp, "playerContent",
                    String::class.java, String::class.java, List::class.java,
                ).invoke(sp, args["flag"]?.toString() ?: "", args["id"]?.toString() ?: "", vip)
            }
            "search" -> {
                val key = args["key"]?.toString() ?: ""
                val quick = args["quick"] == true
                val pg = args["pg"]?.toString()
                if (pg != null) {
                    findMethod(
                        sp, "searchContent",
                        String::class.java, Boolean::class.javaPrimitiveType!!, String::class.java,
                    ).invoke(sp, key, quick, pg)
                } else {
                    findMethod(
                        sp, "searchContent",
                        String::class.java, Boolean::class.javaPrimitiveType!!,
                    ).invoke(sp, key, quick)
                }
            }
            "init" -> findMethod(sp, "init", Context::class.java).invoke(sp, context)
            else -> error("未知方法: $method")
        }
        return ret?.toString() ?: ""
    }

    fun dispose() {
        spider = null
        classLoader = null
        loadedJar = null
    }

    private fun findClass(cl: ClassLoader, name: String): Class<*> {
        val candidates = listOf(
            name,
            "com.github.catvod.spiders.$name",
            "com.github.catvod.csp.$name",
            "csp.$name",
        )
        for (c in candidates) {
            try {
                return cl.loadClass(c)
            } catch (_: ClassNotFoundException) {
            }
        }
        error("找不到蜘蛛类: $name")
    }

    private fun instantiate(clazz: Class<*>, ctx: Context): Any {
        try {
            val ctor = clazz.getConstructor(Context::class.java)
            return ctor.newInstance(ctx)
        } catch (_: NoSuchMethodException) {
        }
        return clazz.getDeclaredConstructor().newInstance()
    }

    private fun findMethod(obj: Any, name: String, vararg params: Class<*>): java.lang.reflect.Method {
        return obj.javaClass.getMethod(name, *params)
    }

    private fun md5Of(file: File): String {
        val digest = MessageDigest.getInstance("MD5")
        file.inputStream().use { input ->
            val buf = ByteArray(8192)
            while (true) {
                val n = input.read(buf)
                if (n <= 0) break
                digest.update(buf, 0, n)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }
}
