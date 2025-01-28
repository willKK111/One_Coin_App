import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:testes_3unidade/UI/widgets/textFielAdd.dart';
import 'package:testes_3unidade/provider/database_provider.dart';

class AddProduto extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AddProdutoState();
}

class _AddProdutoState extends State<AddProduto> {
  final _formKey = GlobalKey<FormState>();
  final _produtoController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _precoController = TextEditingController();

  Future<void> _adicionarProduto({Map<String, dynamic>? produtoSelecionado}) async {
    final produto = produtoSelecionado?['nome'] ?? _produtoController.text;

    if (produto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'O nome do produto não pode estar vazio',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: Colors.redAccent,
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

    if (_formKey.currentState!.validate() || produtoSelecionado != null) {
      final quantidade = produtoSelecionado?['quantidadeSelecionada'] ?? int.parse(_quantidadeController.text);
      final preco = produtoSelecionado?['preco'] ?? double.parse(_precoController.text);

      final database = await Provider.of<DatabaseProvider>(context, listen: false).database;

      await database.insert(
        'estoque',
        {
          'produto': produto,
          'quantidade': quantidade,
          'preco': preco,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Produto ${produtoSelecionado != null ? "selecionado" : "adicionado"} com sucesso!',
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

      if (produtoSelecionado == null) {
        _produtoController.clear();
        _quantidadeController.clear();
        _precoController.clear();
      }

      Provider.of<DatabaseProvider>(context, listen: false).exportToFirebaseDatabase();

      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Adicionar Produtos',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE0E0E0)),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF004D40), Color(0xFF00796B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Preencha os detalhes do produto:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 30),
                buildTextFieldAdiciona(
                  controller: _produtoController,
                  label: 'Nome do Produto',
                  hintText: 'Ex: Lápis, Caneta...',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o nome do produto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                buildTextFieldAdiciona(
                  controller: _quantidadeController,
                  label: 'Quantidade',
                  hintText: 'Ex: 10, 20...',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty || int.tryParse(value) == null) {
                      return 'Informe uma quantidade válida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                buildTextFieldAdiciona(
                  controller: _precoController,
                  label: 'Preço',
                  hintText: 'Ex: 5.50, 10.00...',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty || double.tryParse(value) == null) {
                      return 'Informe um preço válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 310),
                ElevatedButton(
                  onPressed: () {
                    final quantidadeSelecionada = int.tryParse(_quantidadeController.text) ?? 0;

                    if (quantidadeSelecionada > 0) {
                      _adicionarProduto(
                        produtoSelecionado: {
                          'nome': _produtoController.text,
                          'preco': double.tryParse(_precoController.text) ?? 0.0,
                          'quantidadeSelecionada': quantidadeSelecionada,
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Quantidade inválida',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.teal.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Adicionar Produto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _produtoController.dispose();
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }
}
