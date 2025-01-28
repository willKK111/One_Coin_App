import 'package:flutter/material.dart';
import 'package:testes_3unidade/UI/pages/estoque_page.dart';
import 'package:testes_3unidade/UI/pages/relatorio_page.dart';
import 'package:testes_3unidade/UI/pages/venda_page.dart';
import 'package:testes_3unidade/UI/widgets/animatedButton.dart';


class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF004D40), Color(0xFF00796B)],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF004D40), Color(0xFFB2DFDB)],
          ),
        ),
        child: const HomeBody(),
      ),
    );
  }
}

class HomeBody extends StatefulWidget {
  const HomeBody({Key? key}) : super(key: key);

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildAnimatedButton(
            text: "Estoque",
            icon: Icons.inventory,
            color: Colors.teal,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EstoquePage()),
              );
            },
          ),

          const SizedBox(height: 16),

          buildAnimatedButton(
            text: "Vender",
            icon: Icons.point_of_sale,
            color: Colors.teal,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VendaPage()),
              );
            },
          ),

          const SizedBox(height: 16),

          buildAnimatedButton(
            text: "Relatório de Vendas",
            icon: Icons.bar_chart,
            color: Colors.teal,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RelatorioVendasPage()),
              );
            },
          ),
        ],
      ),
    );
  }

}
