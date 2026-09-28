// 桌面 JVM 蜘蛛桥（CatVod Spider 契约）
// 用法: java -cp spider-bridge.jar:your.jar StarJarBridge com.github.catvod.spider.Douban
// 协议: stdin/stdout JSON Lines
//   {"cmd":"init","extend":"..."}
//   {"cmd":"home","filter":true}
//   {"cmd":"homeVod"}
//   {"cmd":"category","tid":"1","pg":1,"filter":true,"extend":{}}
//   {"cmd":"search","key":"爱","quick":false,"pg":1}
//   {"cmd":"detail","ids":"123"}
//   {"cmd":"play","flag":"线路","id":"ep","vipFlags":[]}
//   {"cmd":"exit"}
// 响应: {"ok":true,"data":<json>} / {"ok":false,"error":"..."}
import java.io.*;
import java.lang.reflect.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.*;

public class StarJarBridge {
  static Object spider;
  static Class<?> spiderClass;

  public static void main(String[] args) throws Exception {
    if (args.length < 1) {
      System.err.println("usage: StarJarBridge <com.github.catvod.spider.Xxx>");
      System.exit(2);
    }
    String className = args[0];
    ClassLoader cl = StarJarBridge.class.getClassLoader();
    spiderClass = Class.forName(className, true, cl);
    spider = spiderClass.getDeclaredConstructor().newInstance();

    BufferedReader in = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
    PrintWriter out = new PrintWriter(new OutputStreamWriter(System.out, StandardCharsets.UTF_8), true);
    String line;
    while ((line = in.readLine()) != null) {
      line = line.trim();
      if (line.isEmpty()) continue;
      try {
        out.println(handle(line));
      } catch (Throwable t) {
        out.println(err(t));
      }
      out.flush();
    }
  }

  static String err(Throwable t) {
    StringBuilder sb = new StringBuilder();
    sb.append("{\"ok\":false,\"error\":\"").append(esc(String.valueOf(t))).append("\"}");
    return sb.toString();
  }

  static String esc(String s) {
    return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
  }

  static String handle(String jsonLine) throws Exception {
    Map<String, Object> cmd = parseObj(jsonLine);
    String c = String.valueOf(cmd.getOrDefault("cmd", ""));
    switch (c) {
      case "ping":
        return "{\"ok\":true,\"data\":\"pong\"}";
      case "exit":
        System.exit(0);
        return "{\"ok\":true,\"data\":\"bye\"}";
      case "init": {
        Object extend = cmd.get("extend");
        invoke("init", new Class<?>[]{androidContextClass(), String.class},
            new Object[]{newContext(), extend == null ? "" : String.valueOf(extend)});
        return ok(null);
      }
      case "home": {
        boolean filter = Boolean.TRUE.equals(cmd.get("filter"));
        return ok(invoke("homeContent", new Class<?>[]{boolean.class}, new Object[]{filter}));
      }
      case "homeVod":
        return ok(invokeOptional("homeVideoContent"));
      case "category": {
        String tid = str(cmd, "tid");
        int pg = intOf(cmd, "pg", 1);
        boolean filter = Boolean.TRUE.equals(cmd.get("filter"));
        Map<String, String> extend = strMap(cmd.get("extend"));
        return ok(invoke("categoryContent",
            new Class<?>[]{String.class, int.class, boolean.class, Map.class},
            new Object[]{tid, pg, filter, extend}));
      }
      case "search": {
        String key = str(cmd, "key");
        boolean quick = Boolean.TRUE.equals(cmd.get("quick"));
        int pg = intOf(cmd, "pg", 1);
        return ok(invoke("searchContent",
            new Class<?>[]{String.class, boolean.class, int.class},
            new Object[]{key, quick, pg}));
      }
      case "detail": {
        List<String> ids = new ArrayList<>();
        Object raw = cmd.get("ids");
        if (raw instanceof Collection) {
          for (Object o : (Collection<?>) raw) ids.add(String.valueOf(o));
        } else if (raw != null) {
          ids.add(String.valueOf(raw));
        }
        return ok(invoke("detailContent",
            new Class<?>[]{List.class}, new Object[]{ids}));
      }
      case "play": {
        String flag = str(cmd, "flag");
        String id = str(cmd, "id");
        List<String> vip = new ArrayList<>();
        Object vf = cmd.get("vipFlags");
        if (vf instanceof Collection) {
          for (Object o : (Collection<?>) vf) vip.add(String.valueOf(o));
        }
        return ok(invoke("playerContent",
            new Class<?>[]{String.class, String.class, List.class},
            new Object[]{flag, id, vip}));
      }
      default:
        return "{\"ok\":false,\"error\":\"unknown cmd " + esc(c) + "\"}";
    }
  }

  static String ok(Object data) {
    if (data == null) return "{\"ok\":true,\"data\":null}";
    return "{\"ok\":true,\"data\":" + toJson(data) + "}";
  }

  static Class<?> androidContextClass() throws Exception {
    try {
      return Class.forName("android.content.Context");
    } catch (ClassNotFoundException e) {
      // 桌面无安卓类：用 Object 占位，部分蜘蛛 init 会忽略 Context
      return Object.class;
    }
  }

  static Object newContext() {
    try {
      Class<?> c = Class.forName("android.content.Context");
      return java.lang.reflect.Proxy.newProxyInstance(c.getClassLoader(), new Class<?>[]{c},
          (proxy, method, a) -> {
            String n = method.getName();
            if ("toString".equals(n)) return "StarDesktopContext";
            if ("hashCode".equals(n)) return 0;
            if ("equals".equals(n)) return proxy == (a != null && a.length > 0 ? a[0] : null);
            Class<?> rt = method.getReturnType();
            if (rt == String.class) return "StarDesktopContext";
            if (rt == boolean.class) return false;
            if (rt == int.class || rt == long.class) return 0;
            return null;
          });
    } catch (Throwable t) {
      return null;
    }
  }

  static Object invoke(String name, Class<?>[] types, Object[] args) throws Exception {
    Method m = find(name, types);
    if (m == null) throw new NoSuchMethodException(name);
    m.setAccessible(true);
    return m.invoke(spider, args);
  }

  static Object invokeOptional(String name) throws Exception {
    try {
      Method m = find(name, new Class<?>[0]);
      if (m == null) return null;
      m.setAccessible(true);
      return m.invoke(spider);
    } catch (Exception e) {
      return null;
    }
  }

  static Method find(String name, Class<?>[] types) {
    for (Class<?> c = spiderClass; c != null; c = c.getSuperclass()) {
      try {
        return c.getDeclaredMethod(name, types);
      } catch (NoSuchMethodException ignored) {
      }
    }
    for (Method m : spiderClass.getMethods()) {
      if (m.getName().equals(name) && m.getParameterCount() == types.length) return m;
    }
    return null;
  }

  static String str(Map<String, Object> m, String k) {
    Object v = m.get(k);
    return v == null ? "" : String.valueOf(v);
  }

  static int intOf(Map<String, Object> m, String k, int def) {
    Object v = m.get(k);
    if (v instanceof Number) return ((Number) v).intValue();
    try {
      return Integer.parseInt(String.valueOf(v));
    } catch (Exception e) {
      return def;
    }
  }

  @SuppressWarnings("unchecked")
  static Map<String, String> strMap(Object o) {
    Map<String, String> r = new HashMap<>();
    if (o instanceof Map) {
      for (Map.Entry<?, ?> e : ((Map<?, ?>) o).entrySet()) {
        r.put(String.valueOf(e.getKey()), e.getValue() == null ? "" : String.valueOf(e.getValue()));
      }
    }
    return r;
  }

  // 极简 JSON 解析（只处理本协议）
  static Map<String, Object> parseObj(String s) {
    Map<String, Object> map = new LinkedHashMap<>();
    s = s.trim();
    if (!s.startsWith("{")) return map;
    // 交给 JavaScript 引擎不稳，手写扫描
    parseObjectInto(s, map);
    return map;
  }

  static void parseObjectInto(String s, Map<String, Object> map) {
    int i = 1, n = s.length() - 1;
    while (i < n) {
      while (i < n && (s.charAt(i) == ',' || Character.isWhitespace(s.charAt(i)))) i++;
      if (i >= n) break;
      int keyStart = s.indexOf('"', i);
      if (keyStart < 0) break;
      int keyEnd = s.indexOf('"', keyStart + 1);
      String key = s.substring(keyStart + 1, keyEnd);
      int colon = s.indexOf(':', keyEnd);
      i = colon + 1;
      while (i < n && Character.isWhitespace(s.charAt(i))) i++;
      if (i >= n) break;
      char ch = s.charAt(i);
      if (ch == '"') {
        int end = i + 1;
        StringBuilder sb = new StringBuilder();
        while (end < n) {
          char c = s.charAt(end);
          if (c == '\\' && end + 1 < n) {
            sb.append(s.charAt(end + 1));
            end += 2;
            continue;
          }
          if (c == '"') break;
          sb.append(c);
          end++;
        }
        map.put(key, sb.toString());
        i = end + 1;
      } else if (ch == '{') {
        int end = matchBrace(s, i, '{', '}');
        Map<String, Object> sub = new LinkedHashMap<>();
        parseObjectInto(s.substring(i, end + 1), sub);
        map.put(key, sub);
        i = end + 1;
      } else if (ch == '[') {
        int end = matchBrace(s, i, '[', ']');
        map.put(key, parseArray(s.substring(i, end + 1)));
        i = end + 1;
      } else {
        int end = i;
        while (end < n && s.charAt(end) != ',' && s.charAt(end) != '}' && s.charAt(end) != ']') end++;
        String tok = s.substring(i, end).trim();
        if ("true".equals(tok)) map.put(key, Boolean.TRUE);
        else if ("false".equals(tok)) map.put(key, Boolean.FALSE);
        else if ("null".equals(tok)) map.put(key, null);
        else {
          try {
            if (tok.contains(".")) map.put(key, Double.parseDouble(tok));
            else map.put(key, Integer.parseInt(tok));
          } catch (Exception e) {
            map.put(key, tok);
          }
        }
        i = end;
      }
    }
  }

  static List<Object> parseArray(String s) {
    List<Object> list = new ArrayList<>();
    s = s.trim();
    if (!s.startsWith("[")) return list;
    int i = 1, n = s.length() - 1;
    while (i < n) {
      while (i < n && (s.charAt(i) == ',' || Character.isWhitespace(s.charAt(i)))) i++;
      if (i >= n) break;
      char ch = s.charAt(i);
      if (ch == '"') {
        int end = i + 1;
        StringBuilder sb = new StringBuilder();
        while (end < n && s.charAt(end) != '"') {
          if (s.charAt(end) == '\\') { sb.append(s.charAt(end + 1)); end += 2; continue; }
          sb.append(s.charAt(end));
          end++;
        }
        list.add(sb.toString());
        i = end + 1;
      } else if (ch == '{') {
        int end = matchBrace(s, i, '{', '}');
        Map<String, Object> sub = new LinkedHashMap<>();
        parseObjectInto(s.substring(i, end + 1), sub);
        list.add(sub);
        i = end + 1;
      } else {
        int end = i;
        while (end < n && s.charAt(end) != ',' && s.charAt(end) != ']') end++;
        list.add(s.substring(i, end).trim());
        i = end;
      }
    }
    return list;
  }

  static int matchBrace(String s, int start, char open, char close) {
    int depth = 0;
    for (int i = start; i < s.length(); i++) {
      char c = s.charAt(i);
      if (c == open) depth++;
      else if (c == close) {
        depth--;
        if (depth == 0) return i;
      }
    }
    return s.length() - 1;
  }

  static String toJson(Object o) {
    if (o == null) return "null";
    if (o instanceof String) return "\"" + esc((String) o) + "\"";
    if (o instanceof Number || o instanceof Boolean) return String.valueOf(o);
    if (o instanceof Map) {
      StringBuilder sb = new StringBuilder("{");
      boolean first = true;
      for (Map.Entry<?, ?> e : ((Map<?, ?>) o).entrySet()) {
        if (!first) sb.append(',');
        first = false;
        sb.append("\"").append(esc(String.valueOf(e.getKey()))).append("\":").append(toJson(e.getValue()));
      }
      return sb.append('}').toString();
    }
    if (o instanceof Collection) {
      StringBuilder sb = new StringBuilder("[");
      boolean first = true;
      for (Object x : (Collection<?>) o) {
        if (!first) sb.append(',');
        first = false;
        sb.append(toJson(x));
      }
      return sb.append(']').toString();
    }
    if (o instanceof Object[]) {
      return toJson(Arrays.asList((Object[]) o));
    }
    return "\"" + esc(String.valueOf(o)) + "\"";
  }
}
