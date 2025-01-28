import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testes_3unidade/UI/widgets/buildTextField.dart';
import 'package:testes_3unidade/provider/database_provider.dart';


class mudarProduto extends StatefulWidget {
  final int produtoId;
  final String produtoNome;
  final int quantidadeAtual;
  final double preco;

  mudarProduto({
    required this.produtoId,
    required this.produtoNome,
    required this.quantidadeAtual,
    required this.preco,
  });

  @override
  _mudarProdutoState createState() => _mudarProdutoState();
}

class _mudarProdutoState extends State<mudarProduto> {
  late DatabaseProvider _databaseProvider;
  final _quantidadeController = TextEditingController();
  final _precoController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _databaseProvider = Provider.of<DatabaseProvider>(context);
    _quantidadeController.text = widget.quantidadeAtual.toString();
    _precoController.text = widget.preco.toStringAsFixed(2);
  }

  Future<void> _atualizarProduto() async {
    final db = await _databaseProvider.database;
    final novaQuantidade = int.tryParse(_quantidadeController.text);
    final novoPreco = double.tryParse(_precoController.text);

    if (novaQuantidade == null || novaQuantidade < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insira uma quantidade válida',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
      return;
    }

    if (novoPreco == null || novoPreco <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insira um preço válido',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
      return;
    }

    await db.update(
      'estoque',
      {
        'quantidade': novaQuantidade,
        'preco': novoPreco,
      },
      where: 'id = ?',
      whereArgs: [widget.produtoId],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Produto "${widget.produtoNome}" atualizado!',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );


    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alterar Produto',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade300),
        ),
        backgroundColor:  Color(0xFF00897B),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Produto: ${widget.produtoNome}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Preço Atual: R\$ ${widget.preco.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16, color: Colors.teal.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'Quantidade Atual: ${widget.quantidadeAtual}',
                style: TextStyle(fontSize: 16, color: Colors.teal.shade700),
              ),
              const SizedBox(height: 24),
              buildTextField(
                controller: _quantidadeController,
                label: 'Nova Quantidade',
                hintText: 'Digite a nova quantidade',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              buildTextField(
                controller: _precoController,
                label: 'Novo Preço',
                hintText: 'Digite o novo preço',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 317),
              Center(
                child: ElevatedButton(
                  onPressed: _atualizarProduto,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.teal.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Atualizar Produto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }
}
