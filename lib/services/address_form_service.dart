import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:la_nona/models/user_profile.dart';
import 'package:la_nona/services/user_profile_service.dart';

class AddressFormService {
  const AddressFormService();

  Future<void> showAddressModal(
    BuildContext context, {
    required UserProfileService userProfileService,
    required UserAddress initialAddress,
    required bool isFirstAccess,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: !isFirstAccess,
      builder: (_) {
        return _AddressDialog(
          userProfileService: userProfileService,
          initialAddress: initialAddress,
          isFirstAccess: isFirstAccess,
        );
      },
    );
  }
}

class _AddressDialog extends StatefulWidget {
  const _AddressDialog({
    required this.userProfileService,
    required this.initialAddress,
    required this.isFirstAccess,
  });

  final UserProfileService userProfileService;
  final UserAddress initialAddress;
  final bool isFirstAccess;

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _bairroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _complementoController = TextEditingController();

  bool _isSaving = false;
  bool _isSearchingCep = false;

  static const List<String> _ufs = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  ];

  @override
  void initState() {
    super.initState();
    _cepController.text = widget.initialAddress.cep;
    _ruaController.text = widget.initialAddress.rua;
    _bairroController.text = widget.initialAddress.bairro;
    _numeroController.text = widget.initialAddress.numero;
    _cidadeController.text = widget.initialAddress.cidade;
    _estadoController.text = widget.initialAddress.estado;
    _complementoController.text = widget.initialAddress.complemento;
  }

  @override
  void dispose() {
    _cepController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _numeroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _complementoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isFirstAccess ? 'Complete seu endereço' : 'Atualizar endereço',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _cepController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: InputDecoration(
                  labelText: 'CEP *',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: _isSearchingCep
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          onPressed: _searchCep,
                          icon: const Icon(Icons.search),
                          tooltip: 'Buscar CEP',
                        ),
                ),
                validator: _validateCep,
              ),
              const SizedBox(height: 10),
              _field(_ruaController, 'Rua *', validator: _requiredMin(3)),
              _field(_bairroController, 'Bairro *', validator: _requiredMin(2)),
              _field(_numeroController, 'Número *', validator: _validateNumero),
              _field(_cidadeController, 'Cidade *', validator: _requiredMin(2)),
              _field(
                _estadoController,
                'Estado (UF) *',
                maxLength: 2,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  LengthLimitingTextInputFormatter(2),
                  _UpperCaseTextFormatter(),
                ],
                validator: _validateUf,
              ),
              _field(
                _complementoController,
                'Complemento',
                requiredField: false,
                maxLength: 60,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (!widget.isFirstAccess)
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        TextButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar endereço'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool requiredField = true,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        decoration: const InputDecoration(
          counterText: '',
          border: OutlineInputBorder(),
          isDense: true,
        ).copyWith(labelText: label),
        validator: validator ?? (requiredField ? _requiredMin(1) : null),
      ),
    );
  }

  String? Function(String?) _requiredMin(int min) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return 'Campo obrigatório';
      if (text.length < min) return 'Mínimo de $min caracteres';
      return null;
    };
  }

  String? _validateCep(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'CEP obrigatório';
    if (!widget.userProfileService.isValidCep(text)) {
      return 'CEP inválido';
    }
    return null;
  }

  String? _validateUf(String? value) {
    final uf = (value ?? '').trim().toUpperCase();
    if (uf.isEmpty) return 'UF obrigatória';
    if (!_ufs.contains(uf)) return 'UF inválida';
    return null;
  }

  String? _validateNumero(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Número obrigatório';
    if (!RegExp(r'^[0-9A-Za-z/-]{1,10}$').hasMatch(text)) {
      return 'Número inválido';
    }
    return null;
  }

  Future<void> _searchCep() async {
    final cep = _cepController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (!widget.userProfileService.isValidCep(cep)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Digite um CEP válido para buscar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSearchingCep = true;
    });

    try {
      final fetched = await widget.userProfileService.fetchAddressByCep(cep);
      if (!mounted) return;

      _cepController.text = fetched.cep;
      _ruaController.text = fetched.rua;
      _bairroController.text = fetched.bairro;
      _cidadeController.text = fetched.cidade;
      _estadoController.text = fetched.estado;
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Não foi possível buscar o CEP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingCep = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.userProfileService.saveAddress(
        cep: _cepController.text,
        rua: _ruaController.text,
        bairro: _bairroController.text,
        numero: _numeroController.text,
        cidade: _cidadeController.text,
        estado: _estadoController.text,
        complemento: _complementoController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Endereço salvo com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar endereço: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
