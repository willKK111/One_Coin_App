import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:testes_3unidade/UI/pages/detalhes_venda.dart';
import 'package:testes_3unidade/UI/pages/venda_produto.dart';
import 'package:testes_3unidade/provider/database_provider.dart';
import 'package:animations/animations.dart';

class VendaPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _VendaPageState();
}

class _VendaPageState extends State<VendaPage> {
  late DatabaseProvider _dbProvider;
  Key _key = UniqueKey(); // Chave única para forçar atualização

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dbProvider = Provider.of<DatabaseProvider>(context);
    _verificarBancoDeDados();
  }

  Future<void> _verificarBancoDeDados() async {
    final db = await _dbProvider.database;
    final resultado = await db.query('vendas');
    if (resultado.isEmpty) {
      await _dbProvider.importFromFirebaseDatabase().then((_) {
        setState(() => _key = UniqueKey()); // Atualiza a interface
      });
    }
  }

  Future<List<Map<String, dynamic>>> _carregarVendas() async {
    final db = await _dbProvider.database;
    return await db.query('vendas');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vendas", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade300)),
        centerTitle: true,
        backgroundColor: Color(0xFF00897B),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          key: _key,
          future: _carregarVendas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Erro ao carregar vendas'));
            }

            final vendas = snapshot.data ?? [];
            if (vendas.isEmpty) {
              return const Center(
                child: Text(
                  'Nenhuma venda realizada ainda',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: vendas.length,
              itemBuilder: (context, index) {
                final venda = vendas[index];
                final id = venda['id'];
                final produtosJson = venda['produtos'];
                double total = 0.0;

                if (produtosJson != null && produtosJson is String) {
                  final List<dynamic> produtos = jsonDecode(produtosJson);
                  total = produtos.fold(0.0, (sum, produto) {
                    final quantidade = int.tryParse(produto['quantidadeSelecionada'].toString()) ?? 0;
                    final preco = double.tryParse(produto['preco'].toString()) ?? 0.0;
                    return sum + (quantidade * preco);
                  });
                }

                final metodoPagamento = venda['metodoPagamento'] ?? 'N/A';
                final horario = venda['horario'] ?? 'Horário não disponível';

                return OpenContainer(
                  closedElevation: 5,
                  closedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  closedColor: Colors.white,
                  closedBuilder: (context, openContainer) {
                    return Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Color(0xFF4DB6AC),
                          child: const FaIcon(
                            FontAwesomeIcons.shoppingCart,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          'Venda #$id',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total: R\$ ${total.toStringAsFixed(2)}'),
                              Text('Pagamento: $metodoPagamento'),
                              Text('Horário: $horario'),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
                        onTap: openContainer, // Ao tocar no card, abre a animação
                      ),
                    );
                  },
                  openBuilder: (context, closeContainer) {
                    return VendaDetalhesPage(
                      venda: venda,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: OpenContainer(
        closedElevation: 6,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        closedColor: Colors.teal,
        closedBuilder: (context, openContainer) {
          return FloatingActionButton(
            onPressed: openContainer,
            child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
            backgroundColor: Color(0xFF26A69A),
            tooltip: 'Adicionar Venda',
            elevation: 6,
          );
        },
        openBuilder: (context, closeContainer) {
          return CadastroVendas();
        },
      ),
    );
  }
}
