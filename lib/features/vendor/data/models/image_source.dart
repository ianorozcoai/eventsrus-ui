/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.ImageSource} -
/// which underlying table a [VendorTaggedImage] row actually came from.
enum ImageSource { gallery, package }

extension ImageSourceApi on ImageSource {
  static ImageSource fromApi(String value) {
    switch (value) {
      case 'GALLERY':
        return ImageSource.gallery;
      case 'PACKAGE':
        return ImageSource.package;
      default:
        throw FormatException('Unknown image source: $value');
    }
  }
}
