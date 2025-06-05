import '../../entities/category/category.dart';
import '../../../data/models/category/category_model.dart';

extension CategoryEntityExtension on CategoryEntity {
  CategoryModel toModel() => CategoryModel(
        id: id,
        title: title,
        lastModified: lastModified,
        userId: userId,
      );
}

extension CategoryEntityListExtension on List<CategoryEntity> {
  List<CategoryModel> toModels() => map((entity) => entity.toModel()).toList();
}