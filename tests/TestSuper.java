     class Base {
        public void A() { System.out.println("Base::A"); }
        public void B() { System.out.println("Base::B"); }
    }
    class D1 extends Base {
        public void A() { System.out.println("D1::A"); super.A(); super.B(); }
        public void B() { System.out.println("D1::B"); super.A(); super.B(); }
    }
   class D2 extends D1 {
        public void B() { System.out.println("D2::B"); super.A(); super.B(); }
    }
   class D3 extends D2{
        public void A() { System.out.println("D3::A"); super.A(); super.B(); }
    }
public class TestSuper {


    public static void main(String[] args) {
        Base b = new Base();
        Base d1 = new D1();
        Base d2 = new D2();
        Base d3 = new D3();

        b.A();
        b.B();
        System.out.println();
        d1.A();
        d1.B();
        System.out.println();
        d2.A();
        d2.B();
        System.out.println();
        d3.A();
        d3.B();
    }

}
