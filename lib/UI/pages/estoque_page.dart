import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:testes_3unidade/UI/pages/add_produto.dart';
import 'package:testes_3unidade/UI/pages/alterarProdutoPage.dart';
import 'package:testes_3unidade/provider/database_provider.dart';

class EstoquePage extends StatefulWidget {
  @override
  _EstoquePageState createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  late DatabaseProvider _databaseProvider;
  Key _key = UniqueKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _databaseProvider = Provider.of<DatabaseProvider>(context);
    _verificarBancoDeDados();
  }

  Future<void> _verificarBancoDeDados() async {
    final db = await _databaseProvider.database;
    final resultado = await db.query('estoque');
    if (resultado.isEmpty) {
      await Provider.of<DatabaseProvider>(context, listen: false)
          .importFromFirebaseDatabase()
          .then((_) {
        setState(() {
          _key = UniqueKey();
        });
      });
    }
  }

  Future<List<Map<String, dynamic>>> _carregarEstoque() async {
    final db = await _databaseProvider.database;
    return await db.query('estoque');
  }

  Future<void> _confirmarDelecao(int produtoId, String produtoNome) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Excluir Produto"),
        content: Text("Tem certeza de que deseja excluir o produto \"$produtoNome\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      await _deletarProduto(produtoId);
    }
  }

  Future<void> _deletarProduto(int produtoId) async {
    final db = await _databaseProvider.database;

    await db.delete(
      'estoque',
      where: 'id = ?',
      whereArgs: [produtoId],
    );

    await _databaseProvider.deleteFromFirebaseProduto(produtoId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Produto excluído com sucesso!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.teal,
      ),
    );

    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Estoque",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade300),
        ),
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
          future: _carregarEstoque(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar estoque'));
            }
            final estoque = snapshot.data ?? [];
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              padding: const EdgeInsets.all(16.0),
              itemCount: estoque.length,
              itemBuilder: (context, index) {
                final produto = estoque[index];
                final nome = produto['produto'] ?? 'Produto desconhecido';
                final quantidade = produto['quantidade'] ?? 0;
                final preco = produto['preco']?.toStringAsFixed(2) ?? '0.00';

                return OpenContainer(
                  closedElevation: 6,
                  closedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  closedColor: Colors.white,
                  closedBuilder: (context, openContainer) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.teal.shade50],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Quantidade: $quantidade',
                              style: TextStyle(fontSize: 14, color: Colors.teal.shade700),
                            ),
                            Text(
                              'Preço: R\$ $preco',
                              style: TextStyle(fontSize: 14, color: Colors.teal.shade700),
                            ),
                            Spacer(),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: IconButton(
                                icon: FaIcon(FontAwesomeIcons.trash, size: 20, color: Colors.red),
                                onPressed: () {
                                  _confirmarDelecao(produto['id'], nome);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  openBuilder: (context, openContainer) {
                    return mudarProduto(
                      produtoId: produto['id'],
                      produtoNome: produto['produto'],
                      quantidadeAtual: produto['quantidade'],
                      preco: produto['preco'],
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
            child: FaIcon(FontAwesomeIcons.plus, size: 24),
            backgroundColor: Colors.teal,
          );
        },
        openBuilder: (context, closeContainer) {
          return AddProduto();
        },
      ),
    );
  }
}
