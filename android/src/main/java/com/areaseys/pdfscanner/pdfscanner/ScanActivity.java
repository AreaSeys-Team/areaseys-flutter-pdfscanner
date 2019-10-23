package com.areaseys.pdfscanner.pdfscanner;

import android.Manifest;
import android.app.Activity;
import android.app.FragmentTransaction;
import android.content.ComponentCallbacks2;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.AssetFileDescriptor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;

import java.io.File;
import java.io.IOException;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.content.FileProvider;

/**
 * Created by jhansi on 28/03/15.
 * Last modified: 18/10/2019 by Santi Hoyos
 */
public class ScanActivity extends AppCompatActivity implements IScanner, ComponentCallbacks2 {

    public static final String BUNDLE_EXTRA_KEY_SCAN_SOURCE = "scanSource";
    public static final String BUNDLE_EXTRA_KEY_SCANNED_IMAGES_PATH = "scannedImagesPath";
    public static final String BUNDLE_EXTRA_KEY_SCANNED_IMAGE_NAME = "scannedImageName";
    public static final String BUNDLE_RESULT_KEY_SCANNED_IMAGE_PATH = "scannedImagePath";
    public static final int RESULT_CODE_OK = 78546;
    public static final int RESULT_CODE_ERROR = 78547;
    public static final int BUNDLE_EXTRA_VALUE_OPEN_CAMERA = 4;
    public static final int BUNDLE_EXTRA_VALUE_OPEN_MEDIA_FILE = 5;

    private final int REQUEST_PERMISSIONS_CODE = 1234;
    private final int REQUEST_CODE_PICK_FILE = 4324;
    private final int REQUEST_CODE_START_CAMERA = 4323;
    private Uri fileUri;

    static {
        System.loadLibrary("Scanner");
        System.loadLibrary("opencv_java3");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.scan_layout);
        checkPermissions();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if (requestCode == REQUEST_PERMISSIONS_CODE) {
            if (
                    grantResults.length > 0 &&
                    (grantResults[0] != PackageManager.PERMISSION_GRANTED) || //<-- READ STORAGE
                    (grantResults[1] != PackageManager.PERMISSION_GRANTED) || //<-- CAMERA
                    (grantResults[2] != PackageManager.PERMISSION_GRANTED)    //<-- WRITE STORAGE
            ) {
                setResult(RESULT_CODE_ERROR);
                this.finish();
            }
            else {
                launch();
            }
        }
    }

    @Override
    public void onBitmapSelect(final Uri uri) {
        final ScanFragment fragment = new ScanFragment();
        final Bundle bundle = new Bundle();
        bundle.putParcelable(ScanFragment.BUNDLE_EXTRA_KEY_SELECTED_BITMAP, uri);
        fragment.setArguments(bundle);
        android.app.FragmentManager fragmentManager = getFragmentManager();
        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        fragmentTransaction.add(R.id.content, fragment);
        fragmentTransaction.addToBackStack(ScanFragment.class.toString());
        fragmentTransaction.commit();
    }

    @Override
    public void onScanFinish(final Uri uri) {
        ResultFragment fragment = new ResultFragment();
        Bundle bundle = new Bundle();
        bundle.putParcelable(ResultFragment.BUNDLE_EXTRA_KEY_SCANNED_RESULT, uri);
        fragment.setArguments(bundle);
        android.app.FragmentManager fragmentManager = getFragmentManager();
        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        fragmentTransaction.add(R.id.content, fragment);
        fragmentTransaction.addToBackStack(ResultFragment.class.toString());
        fragmentTransaction.commit();
    }

    @Override
    public void onTrimMemory(int level) {
        switch (level) {
            case ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN:
      /*
         Release any UI objects that currently hold memory.

         The user interface has moved to the background.
      */
                break;
            case ComponentCallbacks2.TRIM_MEMORY_RUNNING_MODERATE:
            case ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW:
            case ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL:
      /*
         Release any memory that your app doesn't need to run.

         The device is running low on memory while the app is running.
         The event raised indicates the severity of the memory-related event.
         If the event is TRIM_MEMORY_RUNNING_CRITICAL, then the system will
         begin killing background processes.
      */
                break;
            case ComponentCallbacks2.TRIM_MEMORY_BACKGROUND:
            case ComponentCallbacks2.TRIM_MEMORY_MODERATE:
            case ComponentCallbacks2.TRIM_MEMORY_COMPLETE:
      /*
         Release as much memory as the process can.

         The app is on the LRU list and the system is running low on memory.
         The event raised indicates where the app sits within the LRU list.
         If the event is TRIM_MEMORY_COMPLETE, the process will be one of
         the first to be terminated.
      */
                /* new AlertDialog.Builder(this)
                        .setTitle(R.string.low_memory)
                        .setMessage(R.string.low_memory_message)
                        .create()
                        .show();  */
                break;
            default:
      /*
        Release any non-critical data structures.

        The app received an unrecognized memory level value
        from the system. Treat this as a generic low-memory message.
      */
                break;
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        Bitmap bitmap = null;
        if (resultCode == Activity.RESULT_OK) {
            try {
                switch (requestCode) {
                    case REQUEST_CODE_START_CAMERA:
                        bitmap = getBitmap(fileUri);
                        break;

                    case REQUEST_CODE_PICK_FILE:
                        bitmap = getBitmap(data.getData());
                        break;
                }
            }
            catch (Exception e) {
                e.printStackTrace();
            }
        }
        else {
            finish();
        }
        if (bitmap != null) {
            postImagePick(bitmap);
        }
    }

    public native Bitmap getScannedBitmap(Bitmap bitmap, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4);

    public native Bitmap getGrayBitmap(Bitmap bitmap);

    public native Bitmap getMagicColorBitmap(Bitmap bitmap);

    public native Bitmap getBWBitmap(Bitmap bitmap);

    public native float[] getPoints(Bitmap bitmap);

    public void openMediaContent() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("image/*");
        startActivityForResult(intent, REQUEST_CODE_PICK_FILE);
    }

    public final void openCamera() {
        final Intent cameraIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        final File file = createImageFile();
        file.getParentFile().mkdirs();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            final Uri tempFileUri = FileProvider.getUriForFile(getApplicationContext(), "com.areaseys_authority", file);
            cameraIntent.putExtra(MediaStore.EXTRA_OUTPUT, tempFileUri);
        }
        else {
            final Uri tempFileUri = Uri.fromFile(file);
            cameraIntent.putExtra(MediaStore.EXTRA_OUTPUT, tempFileUri);
        }
        startActivityForResult(cameraIntent, REQUEST_CODE_START_CAMERA);
    }

    protected void postImagePick(final Bitmap bitmap) {
        Uri uri = UtilsKt.getUri(this, bitmap);
        bitmap.recycle();
        onBitmapSelect(uri);
    }

    private File createImageFile() {
        clearTempImages();
        File file = new File(
                Environment.getExternalStorageDirectory().getPath() + getIntent().getStringExtra(BUNDLE_EXTRA_KEY_SCANNED_IMAGES_PATH),
                getIntent().getStringExtra(BUNDLE_EXTRA_KEY_SCANNED_IMAGE_NAME)
        );
        fileUri = Uri.fromFile(file);
        return file;
    }

    /**
     * Check permissions and request if is necessary.
     */
    private void checkPermissions() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.CAMERA,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE
            }, REQUEST_PERMISSIONS_CODE);
        }
        else {
            launch();
        }
    }

    private void launch() {
        if (getIntent() != null && getIntent().getExtras() != null) {
            if (getIntent().getExtras().getInt(BUNDLE_EXTRA_KEY_SCAN_SOURCE) == BUNDLE_EXTRA_VALUE_OPEN_CAMERA) {
                openCamera();
            }
            else if (getIntent().getExtras().getInt(BUNDLE_EXTRA_KEY_SCAN_SOURCE) == BUNDLE_EXTRA_VALUE_OPEN_MEDIA_FILE) {
                openMediaContent();
            }
        }
        else {
            finish();
        }
    }



    private Bitmap getBitmap(Uri selectedimg) throws IOException {
        final BitmapFactory.Options options = new BitmapFactory.Options();
        options.inSampleSize = 3;
        AssetFileDescriptor fileDescriptor;
        fileDescriptor = getContentResolver().openAssetFileDescriptor(selectedimg, "r");
        final Bitmap original = BitmapFactory.decodeFileDescriptor(fileDescriptor.getFileDescriptor(), null, options);
        return original;
    }

    private void clearTempImages() {
        try {
            final String imagePath = getIntent().getStringExtra(BUNDLE_EXTRA_KEY_SCANNED_IMAGES_PATH);
            File tempFolder = new File(imagePath);
            for (File f : tempFolder.listFiles())
                f.delete();
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}