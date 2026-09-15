import 'package:flutter/material.dart';
import 'main.dart'; // Para acessar a variável 'supabase'

class Catalogo extends StatefulWidget {
  const Catalogo({super.key});

  @override
  State<Catalogo> createState() => _CatalogoState();
}

class _CatalogoState extends State<Catalogo> {
  // Controles de texto
  final txtTitulo = TextEditingController();
  final txtGenero = TextEditingController();
  final txtPlataforma = TextEditingController();
  final txtNota = TextEditingController();

  // Variável para saber se já assistiu
  bool assistiuCheckbox = false;

  // Variável para saber qual filme estamos editando
  int? idFilmeEmEdicao;

  @override
  void dispose() {
    txtTitulo.dispose();
    txtGenero.dispose();
    txtPlataforma.dispose();
    txtNota.dispose();
    super.dispose();
  }

  // CREATE / UPDATE
  Future<void> salvarOuAtualizarFilme() async {
    final titulo = txtTitulo.text;
    final genero = txtGenero.text;
    final plataforma = txtPlataforma.text;
    final nota = double.tryParse(txtNota.text) ?? 0.0;

    if (titulo.isEmpty) return;

    if (idFilmeEmEdicao == null) {
      // CREATE: Novo registro
      await supabase.from('catalogo').insert({
        'titulo': titulo,
        'genero': genero,
        'plataforma': plataforma,
        'assistido': assistiuCheckbox,
        'nota': nota,
      });
    } else {
      // UPDATE: Atualiza o existente
      await supabase.from('catalogo').update({
        'titulo': titulo,
        'genero': genero,
        'plataforma': plataforma,
        'assistido': assistiuCheckbox,
        'nota': nota,
      }).eq('id', idFilmeEmEdicao!);

      idFilmeEmEdicao = null;
    }

    limparCampos();
  }

  // DELETE
  Future<void> excluirFilme(int id) async {
    await supabase.from('catalogo').delete().eq('id', id);
  }

  // Prepara o formulário para edição
  void prepararEdicao(Map<String, dynamic> filme) {
    setState(() {
      idFilmeEmEdicao = filme['id'];
      txtTitulo.text = filme['titulo'] ?? '';
      txtGenero.text = filme['genero'] ?? '';
      txtPlataforma.text = filme['plataforma'] ?? '';
      txtNota.text = filme['nota']?.toString() ?? '';
      assistiuCheckbox = filme['assistido'] ?? false;
    });
  }

  void limparCampos() {
    txtTitulo.clear();
    txtGenero.clear();
    txtPlataforma.clear();
    txtNota.clear();
    setState(() {
      assistiuCheckbox = false;
      idFilmeEmEdicao = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Filmes e Séries',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // === FORMULÁRIO ===
            TextField(
                controller: txtTitulo,
                decoration: const InputDecoration(
                    labelText: 'Título', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: txtGenero,
                decoration: const InputDecoration(
                    labelText: 'Gênero (Ação, Drama...)',
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: txtPlataforma,
                decoration: const InputDecoration(
                    labelText: 'Plataforma (Netflix, HBO...)',
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: txtNota,
                        decoration: const InputDecoration(
                            labelText: 'Nota (0 a 10)',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Text('Já Assistiu?'),
                    Switch(
                        value: assistiuCheckbox,
                        onChanged: (bool valor) {
                          setState(() {
                            assistiuCheckbox = valor;
                          });
                        }),
                  ],
                )
              ],
            ),
            const SizedBox(height: 15),

            // Botões de Salvar/Cancelar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white),
                    onPressed: salvarOuAtualizarFilme,
                    child: Text(idFilmeEmEdicao == null
                        ? 'Salvar Novo'
                        : 'Atualizar Filme'),
                  ),
                ),
                if (idFilmeEmEdicao != null) ...[
                  const SizedBox(width: 10),
                  TextButton(
                      onPressed: limparCampos,
                      child: const Text('Cancelar',
                          style: TextStyle(color: Colors.red))),
                ],
              ],
            ),
            const Divider(height: 30),

            // === LISTA DE FILMES (READ) ===
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .from('catalogo')
                    .stream(primaryKey: ['id']).order('id', ascending: true),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final filmes = snapshot.data!;
                  if (filmes.isEmpty)
                    return const Center(
                        child: Text('Nenhum filme salvo na lista.'));

                  return ListView.builder(
                    itemCount: filmes.length,
                    itemBuilder: (context, index) {
                      final filme = filmes[index];
                      final bool isAssistido = filme['assistido'] ?? false;

                      return Card(
                        elevation: 2,
                        child: ListTile(
                          leading: Icon(
                            isAssistido
                                ? Icons.check_circle
                                : Icons.watch_later,
                            color: isAssistido ? Colors.green : Colors.orange,
                            size: 30,
                          ),
                          title: Text(filme['titulo'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Plataforma: ${filme['plataforma']}\nStatus: ${isAssistido ? "Assistido (Nota: ${filme['nota']})" : "Quero ver"}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () => prepararEdicao(filme)),
                              IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => excluirFilme(filme['id'])),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
