import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testes_3unidade/UI/widgets/infoRow.dart';
import 'package:testes_3unidade/provider/database_provider.dart';

class VendaDetalhesPage extends StatelessWidget {
  final Map<String, dynamic> venda;

  const VendaDetalhesPage({Key? key, required this.venda}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Verifica e decodifica a string JSON para uma lista
    final produtos = venda['produtos'] is String
        ? json.decode(venda['produtos']) as List<dynamic>
        : venda['produtos'] ?? [];

    final total = produtos.fold(0.0, (sum, produto) {
      final quantidade = int.tryParse(produto['quantidadeSelecionada'].toString()) ?? 0;
      final preco = double.tryParse(produto['preco'].toString()) ?? 0.0;
      return sum + (quantidade * preco);
    });

    final metodoPagamento = venda['metodoPagamento'] ?? 'N/A';
    final horario = venda['horario'] ?? 'Horário não disponível';
    final nome = venda['nome'];
    final cpf = venda['cpf'] ?? 'CPF não informado';
    final int idVenda = venda['id']; // Obtém o id da venda

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detalhes da Venda',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.grey.shade300),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes da Venda',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
            ),
            const SizedBox(height: 20),
            buildInfoRow('Total:', 'R\$ ${total.toStringAsFixed(2)}'),
            buildInfoRow('Método de Pagamento:', metodoPagamento),
            buildInfoRow('Horário:', horario),
            buildInfoRow('Nome:', nome),
            buildInfoRow('CPF:', cpf),
            const SizedBox(height: 20),
            Text(
              'Produtos:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: produtos.length,
                itemBuilder: (context, index) {
                  final produto = produtos[index];
                  final nomeProduto = produto['produto'];
                  final quantidade = produto['quantidadeSelecionada'];
                  final preco = produto['preco'];

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 3,
                    child: ListTile(
                      title: Text(
                        nomeProduto,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Quantidade: $quantidade | Preço: R\$ $preco',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      leading: const Icon(
                        Icons.shopping_cart,
                        color: Colors.teal,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Voltar à tela anterior
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.teal.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    _showDeleteDialog(context, idVenda);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Deletar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Função para exibir a caixa de diálogo de confirmação
  void _showDeleteDialog(BuildContext context, int idVenda) {
    final database = Provider.of<DatabaseProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta venda?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await database.deleteVenda(idVenda);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Sim'),
          ),
        ],
      ),
    );
  }
}
