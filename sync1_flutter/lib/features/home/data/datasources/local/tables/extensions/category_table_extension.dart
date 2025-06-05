
import '../../../../../../../core/database/local/database.dart';
import '../../../../models/category/category_model.dart';

extension CategoryTableDataExtensions on CategoryTableData {
  CategoryModel toModel() => CategoryModel(id: id, title: title, lastModified: lastModified, userId: userId);
}

extension CategoryTableDataListExtensions on List<CategoryTableData> {
  List<CategoryModel> toModels() => map((data)=> data.toModel()).toList();
}

