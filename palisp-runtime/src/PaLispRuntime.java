
/**
 * Contains built-in functions for PA-LISP implemented in Java.
 * Since PA-LISP is dynamically typed, the solution has been to 
 * use Objects everywhere, and cast them to more specific 
 * types when necessary. 
 */
public class PaLispRuntime {
	
	public static Object plus(Object a, Object b) {
		return ((Integer)a).intValue() + ((Integer)b).intValue(); 
	}
	
	public static Object minus(Object a, Object b) {
		return ((Integer)a).intValue() - ((Integer)b).intValue(); 
	}
	
	public static Object multiply(Object a, Object b) {
		return ((Integer)a).intValue() * ((Integer)b).intValue(); 
	}

	public static Object divide(Object a, Object b) {
		return ((Integer)a).intValue() / ((Integer)b).intValue(); 
	}
	
	public static Object lessThan(Object a, Object b) {
		if (((Integer)a).intValue() < ((Integer)b).intValue()) {
			return new Integer(1);
		} else {
			return new Integer(0);
		}
	}
	
	public static Object greaterThan(Object a, Object b) {
		if (((Integer)a).intValue() > ((Integer)b).intValue()) {
			return new Integer(1);
		} else {
			return new Integer(0);
		}
	}
	
	public static Object equal(Object a, Object b) {
		if (a.equals(b)) {
			return new Integer(1);
		} else {
			return new Integer(0);
		}
	}
	
	public static Object println(Object val) {
		System.out.println(val);
		return val;
	}
	
	/**
	 * Checks whether the parameter is integer (casts, if 
	 * cast fails, ClassCastException is thrown), and 
	 * whether it's 0 or 1 (the "boolean values" which are
	 * accepted). 
	 * 
	 * 
	 * @return the primitive int value.
	 */
	public static int checkBoolean(Object param) {
		int intval = ((Integer)param).intValue();
		if (intval != 0 && intval != 1) {
			throw new IllegalStateException("Not a boolean: " + param);
		}
		return intval;
	}
}
