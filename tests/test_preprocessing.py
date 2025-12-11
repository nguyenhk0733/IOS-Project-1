import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

from src.python import preprocessing


class TestUtilities(unittest.TestCase):
    def test_is_url(self):
        self.assertTrue(preprocessing._is_url("http://example.com"))
        self.assertTrue(preprocessing._is_url("https://example.com"))
        self.assertFalse(preprocessing._is_url("ftp://example.com"))
        self.assertFalse(preprocessing._is_url(123))

    def test_sanitize_filename(self):
        self.assertEqual(preprocessing._sanitize_filename("  my file @#$ .png  "), "my_file__.png")
        self.assertEqual(preprocessing._sanitize_filename("ảnh đặc biệt.jpg"), "nh_c_bit.jpg")


class TestImageOps(unittest.TestCase):
    def create_image(self, size, color):
        return Image.new("RGB", size, color)

    def test_center_crop_square(self):
        img = self.create_image((200, 100), (10, 20, 30))
        cropped = preprocessing.center_crop_square(img)
        self.assertEqual(cropped.size, (100, 100))
        # The leftmost pixel should match the original center region
        self.assertEqual(cropped.getpixel((0, 0)), (10, 20, 30))

    def test_letterbox_resize_padding(self):
        img = self.create_image((200, 100), (255, 0, 0))
        resized = preprocessing.letterbox_resize(img, target_size=(128, 128), pad_color=(255, 255, 255))
        self.assertEqual(resized.size, (128, 128))

        # Top-left corner should be padding color, center should remain red
        self.assertEqual(resized.getpixel((0, 0)), (255, 255, 255))
        self.assertEqual(resized.getpixel((64, 64)), (255, 0, 0))

    def test_light_denoise_strengths(self):
        img = self.create_image((32, 32), (128, 128, 128))
        self.assertIs(preprocessing.light_denoise(img, strength="none"), img)
        for strength in ("median", "sharpen"):
            filtered = preprocessing.light_denoise(img, strength=strength)
            self.assertEqual(filtered.size, img.size)


class TestPrepForModel(unittest.TestCase):
    def test_prep_add_batch_and_normalize(self):
        img = Image.new("RGB", (10, 10), (255, 255, 255))
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "white.jpg"
            img.save(path)

            arr = preprocessing.prep_for_model(path, target_size=(8, 8), strategy="center-crop", normalize="0_1")
            self.assertEqual(arr.shape, (1, 8, 8, 3))
            self.assertTrue(np.allclose(arr, 1.0))

    def test_prep_without_batch_imagenet_norm(self):
        img = Image.new("RGB", (10, 10), (0, 0, 0))
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "black.jpg"
            img.save(path)

            arr = preprocessing.prep_for_model(
                path,
                target_size=(4, 4),
                strategy="center-crop",
                normalize="imagenet",
                add_batch_dim=False,
            )
            self.assertEqual(arr.shape, (4, 4, 3))
            expected = (-np.array([0.485, 0.456, 0.406], dtype="float32") / np.array([0.229, 0.224, 0.225], dtype="float32"))
            self.assertTrue(np.allclose(arr, expected))


class TestDownloadAndSave(unittest.TestCase):
    def test_download_and_save_local_path(self):
        img = Image.new("RGB", (5, 5), (1, 2, 3))
        with tempfile.TemporaryDirectory() as tmpdir:
            src_path = Path(tmpdir) / "source.png"
            img.save(src_path)

            out_path = preprocessing.download_and_save(str(src_path), tmpdir)
            self.assertTrue(out_path.exists())
            saved = Image.open(out_path)
            self.assertEqual(saved.size, img.size)
            self.assertEqual(saved.getpixel((0, 0)), (1, 2, 3))
