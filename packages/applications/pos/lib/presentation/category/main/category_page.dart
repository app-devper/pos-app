import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:pos/presentation/core/page_bar.dart';
import 'package:design_system/widgets/snack_bar.dart';
import 'package:design_system/widgets/error_state.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/category/category.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/category/argument.dart';
import 'package:pos/presentation/core/list_empty_state.dart';
import 'package:pos/presentation/constants.dart';
import 'category_state.dart';
import 'category_view_model.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<StatefulWidget> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late CustomSnackBar _snackBar;
  late CategoryViewModel _viewModel;
  late StreamSubscription<String> _errors;

  @override
  void initState() {
    super.initState();
    _viewModel = sl<CategoryViewModel>();
    _errors = _viewModel.errors.listen(_showError);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.getCategories();
    });
  }

  void _showError(String message) {
    _snackBar.hideAll();
    _snackBar.showErrorSnackBar(message);
  }

  @override
  void dispose() {
    _errors.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _snackBar = CustomSnackBar(key: const Key("snackbar"), context: context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: buildPageBar(
        context,
        Languages.of(context).categoryTitle,
        actions: _buildAction(context),
      ),
      body: _buildBody(context),
    );
  }

  List<Widget> _buildAction(BuildContext context) {
    return [
      IconButton(
        tooltip: Languages.of(context).addCategory,
        splashRadius: 20,
        onPressed: () {
          _nextToCategoryAdd(context);
        },
        icon: const Icon(Icons.add),
      ),
    ];
  }

  Widget _buildBody(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height,
      width: size.width,
      child: Column(
        children: <Widget>[
          _buildCategoryList(),
        ],
      ),
    );
  }

  ValueListenableBuilder<CategoryState> _buildCategoryList() {
    return ValueListenableBuilder<CategoryState>(
      valueListenable: _viewModel.state,
      builder: (BuildContext context, CategoryState state, _) {
        // A failed load is not an empty shop: it says so, with a retry.
        if (state.error != null && state.items.isEmpty) {
          return Expanded(
            child: ErrorState(
                message: state.error!, onRetry: _viewModel.getCategories),
          );
        }
        if (state.loading && state.items.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: Theme.of(context).colorScheme.primary,
              strokeCap: StrokeCap.round,
            ),
          );
        }
        if (state.items.isEmpty) {
          return Expanded(
            child: ListEmptyState(
              searched: false,
              icon: Icons.category_outlined,
              title: Languages.of(context).noCategoriesYet,
              addLabel: Languages.of(context).addFirstCategory,
              onAdd: () => _nextToCategoryAdd(context),
            ),
          );
        }
        return _buildCategory(state.items);
      },
    );
  }

  Expanded _buildCategory(List<Category> item) {
    return Expanded(
      child: ListView.builder(
        itemCount: item.length,
        itemBuilder: (context, index) {
          final content = item[index];
          return ListTile(
            title: Text(content.name),
            subtitle: Text(content.value),
            onTap: () {
              _nextToCategoryEdit(context, content);
            },
          );
        },
      ),
    );
  }

  Future<void> _nextToCategoryEdit(
      BuildContext context, Category content) async {
    var _ = await Navigator.pushNamed(context, categoryEditRoute,
        arguments: CategoryArgument(content));
    _viewModel.getCategories();
  }

  Future<void> _nextToCategoryAdd(BuildContext context) async {
    var _ = await Navigator.pushNamed(context, categoryAddRoute);
    _viewModel.getCategories();
  }
}
