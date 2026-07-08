import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../models/payment_provider.dart';
import 'receipt_reference_patterns.dart';
import 'receipt_ocr_result.dart';

abstract class ReceiptOcrService {
  bool get isAvailable;

  Future<ReceiptOcrResult?> scanReceipt({required PaymentProvider provider});
}

class UnsupportedReceiptOcrService implements ReceiptOcrService {
  const UnsupportedReceiptOcrService();

  @override
  bool get isAvailable => false;

  @override
  Future<ReceiptOcrResult?> scanReceipt({
    required PaymentProvider provider,
  }) async {
    return null;
  }
}

class AndroidMlKitReceiptOcrService implements ReceiptOcrService {
  AndroidMlKitReceiptOcrService({
    ImagePicker? imagePicker,
    TextRecognizer Function()? textRecognizerFactory,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _textRecognizerFactory =
           textRecognizerFactory ??
           (() => TextRecognizer(script: TextRecognitionScript.latin));

  final ImagePicker _imagePicker;
  final TextRecognizer Function() _textRecognizerFactory;

  @override
  bool get isAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<ReceiptOcrResult?> scanReceipt({
    required PaymentProvider provider,
  }) async {
    if (!isAvailable) {
      return null;
    }

    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage == null) {
      return null;
    }

    final textRecognizer = _textRecognizerFactory();
    try {
      final inputImage = InputImage.fromFilePath(pickedImage.path);
      final recognizedText = await textRecognizer.processImage(inputImage);
      return ReceiptReferencePatterns.parse(provider, recognizedText.text);
    } finally {
      await textRecognizer.close();
    }
  }
}

ReceiptOcrService createDefaultReceiptOcrService() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidMlKitReceiptOcrService();
  }

  return const UnsupportedReceiptOcrService();
}

final receiptOcrServiceProvider = Provider<ReceiptOcrService>((ref) {
  return createDefaultReceiptOcrService();
});
