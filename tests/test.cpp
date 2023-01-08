#include <iostream>

namespace CptPoint {
    int next;
    int get() { return next; }
    int incr() { next = next + 1; return next;}
}

struct Point
{
    Point(int xc, int yc)
    { /* corps du constructeur */
        this->x = xc; this->y = yc;
        this->index = CptPoint::incr();
        this->setName("Point_" + std::to_string(this->index));
        this->hasClone = 0;
    }
  int x;
  int getX() { return x; }
  int y;
  int getY() { return y; }
  int hasClone;
  std::string name;
  int index;
  std::string getName() { return name; }
  /* la valeur du champ ci-dessous est indefinie si hasClone vaut 0.
   * Le probleme est qu'on n'a pas l'equivalent de NULL (du bon type)
   */
   Point* clone;

  void setName(std::string newName) { this->name = newName; }

    int isCloned() { return this->hasClone != 0; }

  Point* move(int dx, int dy, int verbose) {
      this->x = this->x + dx;
      this->y = this->getY() + dy; /* usage de la methode definie automatiquement */
      if (verbose) { this->print(verbose); } else {}
      /* pseudo variable 'result' dans laquelle, par convention, on laisse
       * la valeur de retour d'une fonction qui a un type de retour.
       * On aurait pu ecrire aussi
       * return this;
       */
      return this;
  }

  virtual void print(int verbose) {
      if (verbose) std::cout << "Inside Point::print\n"; else { }
      /* Exemples avec l'operateur & de concatenation de chaines */
      std::cout << this->name;
      std::cout << "= (" << this->x << ", " << this->y << ")\n";
  }

  /* par defaut, on ajoute un ' au nom de l'objet. Modifiable avec setName */
  virtual Point* doclone()
  { this->hasClone = 1;
   /* On memorise le dernier clone construit à partir de cet objet
    * si on voulait on pourrait le chainer a la fin de la liste des clones
    */
    // ERROR x1 : this->clone = new Point(this->x, this->y, this->name & "'");
    this->clone = new Point(this->x, this->y);
    this->clone->setName(this->name + "'");
    return this->clone;
  }

  /* imprime le clone de cet objet, s'il existe, ainsi que recursivement
   * les clones de ce dernier
   */
  void allClones () {
    if (this->hasClone != 0) { this->clone->print(1); this->clone->allClones(); }
    else { }
  }

  int egal(Point* p) {  /* autre version */
    int b1, b2;
    b1 = p->getX() - this->getX();
    b2 = p->getY() - this->y; /* acces direct au champ y ppour this */
    if (b1) { return 0; } else { return b2 == 0; }
  }
}; /* Fin de la classe Point */

struct Couleur {
    Couleur(int c)
   {
      /* 3 couleurs codees par 0, 1 ou 2
       * Le corps du constructeur garantit qu'on a bien que trois couleurs.
       */
      if (c < 0) this->coul = 0;
      else if (c > 2) this->coul = 2; else { this->coul = c; }
   }
   int coul;
   std::string name(int verbose) {
      std::string aux;
      if (verbose) std::cout << "Inside Couleur::couleur\n"; else {}
      if (this->coul == 0) return "Blanc";
      else { std::string dummy;
	         dummy = "Noir"; aux = "Gris";
             if (this->coul == 1) aux = dummy; else { }
	         return aux;
           }
   }

   int estGris() {
     std::cout << "Inside Couleur::estGris\n";
     return this->coul == 2;
   }
};

namespace CouleurFactory {
      Couleur* blanc = new Couleur(0);
      Couleur* noir  = new Couleur(1);
      Couleur* gris  = new Couleur(2);
    Couleur* Blanc() { return blanc; }
    Couleur* Noir() { return noir; }
    Couleur* Gris() { return gris; }
}

struct PointColore : public Point {

  PointColore(int xc, int yc, Couleur* c) : Point(xc, yc)
  { this->couleur = c; setName("PC_" + std::to_string(this->index)); } // ERROR x2 : missing 'this' (couleur = c et index.toString())
   Couleur* couleur;
   virtual Couleur* getCouleur() { return couleur; }

    virtual int colore() { return this->couleur->estGris() != 0; }

 /* pas PointColore: pas de covariance ! On ne peut pas reutiliser le
  * clone de Point car ca nous donnerait une instance de Point.
  * On n'a pas le mecanisme predefini de Java qui permet de remonter jusqu'a
  * la racine de la hierarchie tout en allouant un objet de la bonne classe.
  */
    Point* doclone() override  {/* pas PointColore. Pas de covariance ! */
           /* ci-dessous x et y sont les champs herites de Point */
        return new PointColore(this->x, this->y, this->couleur); }

   virtual int estGris() {return this->couleur->estGris();} // ERROR x1 : why this->coul ?

   void print(int verbose) override {
      if (verbose) std::cout << "Inside PointColore::print\n"; else { }
      Point::print(verbose);  /* usage classique de super */
      std::cout << this->getCouleur()->name(1) << "\n";
   }
};

struct PointNoir : public PointColore {
    PointNoir(int xc, int yc) : PointColore(xc, yc, CouleurFactory::Noir()) {}
    int estGris() override { return 0; }
    int colore() override { return 1; }
    Couleur* getCouleur() override { return CouleurFactory::Noir(); }
};


struct DefaultPoint : public PointColore {
        DefaultPoint() : PointColore(0, 0, CouleurFactory::Blanc()) {}
        int estGris() override { return 0; }
        Couleur* getCouleur() override { return CouleurFactory::Blanc(); }
};

namespace Test {
   void test(Point* p, PointColore* p2, PointNoir* p3) {
      std::string c, c2, c3;
      int True;
      True = 1;
      p->print(true);
      p2->print(true);
      std::cout << "Appel 1: \n";
      if (p2->colore() != 0) c = "colore";  else c = "gris";
      std::cout << "Appel 2: \n";
      if (p3->colore() != 0) c2 = "colore"; else c2 = "gris";
      std::cout << "Appel 3: \n";
      if (p3->colore() != 0) c3 = "colore"; else c3 = "gris";
      std::cout << "Resultats de test: \n";
      std::cout << c << " ";
      std::cout << c2 << " ";
      std::cout << c3;
      std::cout << '\n';
       /* imprime une ligne vide */
   }

   void test2(PointColore* p) { std::cout << p->getCouleur()->name(1) << "\n"; }

}

int main()
{ /* Bloc qui correspond au programme principal */
  Point* p1, *p2, *p3, *clone1, *clone2;
  int True, False, fv;
  PointColore* o;
  PointNoir* pn;
  DefaultPoint* dp;
  std::cout << "Debut du programme\n";
  True = 1;
  False = 0;
  p1 = new Point(1, 5);
  p2 = new Point(2, 3);
  p3 = new Point(0, 0);
  fv = 12;
  o = new PointColore(0, 0, CouleurFactory::Blanc());
  pn = new PointNoir(+1, -1);
  dp = new DefaultPoint();
  p1->print(0);
  p2->print(0);
  // ERROR x2 : p2.move(p1.getx(), p1.gety(), 0); // Getter is p.x() / p.y()
  p2->move(p1->getX(), p1->getY(), 0);
  p2->print(0);
  o->print(0);
  o->setName("origine");
  o->print(True);
  // ERROR x2 : p2.move(p1.getx()-2*5-3, p1.gety(), 0); // Getter is p.x() / p.y()
  p2->move(p1->getX()-2*5-3, p1->getY(), 0);
  p2->print(True);

  std::cout << "On va essayer le clonage:\n";
  clone1 = p1->doclone(); clone1->print(false);
  std::cout << "p1 isCloned: ";
  if (p1->isCloned()) std::cout << "OK\n"; else std::cout << "KO\n";
  clone2 = clone1->doclone(); clone2->move(54, 36, 0)->print(false);

  std::cout << "Impression de tous les clones de p1:\n";
   p1->allClones();
  std::cout << "Fin de l'impression de tous les clones\n";

  /* Ne doit pas compiler car clone() renvoie statiquement un Point alors
   * que o est declare comme PointColore
   * o = o.clone();
   */

  std::cout << "Valeur du compteur de nombre de points: \n";
  // ERROR x1 : Point.get().toString().println();
  std::cout << CptPoint::get() << "\n";

  p1 = p1->doclone()->move(+2, -3, 0);
  p1->print(true);
  o->doclone()->print(true);
  std::cout << "test(Point, PointColore, PointNoir)\n";
  Test::test(p1, o, pn);
  std::cout << "test(PointNoir, PointNoir, PointNoir)\n";
  Test::test(pn, pn, pn);
  p1 = pn; /* affectation entre references ! */
  Test::test2(o);
  Test::test2(pn);
  o = pn;  /* Idem : on doit avoir de la liaison dynamique ci-dessous */

  std::cout << "test(PointNoir, PointNoir, PointNoir)\n";
  Test::test(p1, o, pn);
  Test::test2(o);
  Test::test2(pn);
  std::cout << "\nDone\n";
}
