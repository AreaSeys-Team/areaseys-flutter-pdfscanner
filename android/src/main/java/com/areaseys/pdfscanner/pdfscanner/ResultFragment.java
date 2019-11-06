package com.areaseys.pdfscanner.pdfscanner;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.Fragment;
import android.app.FragmentManager;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.PorterDuff;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;

import java.io.File;
import java.io.IOException;

import androidx.core.content.ContextCompat;

/**
 * Created by jhansi on 29/03/15.
 * modified by SantiiHoyos on 24/10/19
 */
public class ResultFragment extends Fragment {

    public static final String BUNDLE_EXTRA_KEY_SCANNED_RESULT = "scannedResult";
    public static final String BUNDLE_EXTRA_KEY_IMAGES_PATH = "scannedImagesPath";
    public static final String BUNDLE_EXTRA_KEY_IMAGE_NAME = "scannedImageName";

    private View view;
    private ImageView scannedImageView;
    private Bitmap original;
    private Bitmap transformed;
    private static ProgressDialogFragment progressDialogFragment;

    private Button lastclicked;

    @Override
    @SuppressLint("InflateParams")
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        view = inflater.inflate(R.layout.result_layout, null);
        init();
        return view;
    }

    private void init() {
        scannedImageView = view.findViewById(R.id.scannedImage);
        Button originalButton = view.findViewById(R.id.original);
        originalButton.setOnClickListener(new OriginalButtonClickListener());
        Button magicColorButton = view.findViewById(R.id.magicColor);
        magicColorButton.setOnClickListener(new MagicColorButtonClickListener());
        Button grayModeButton = view.findViewById(R.id.grayMode);
        grayModeButton.setOnClickListener(new GrayButtonClickListener());
        Button bwButton = view.findViewById(R.id.BWMode);
        bwButton.setOnClickListener(new BWButtonClickListener());
        scannedImageView.setImageBitmap(check4AvoidTooLargeOpenGLError(getBitmap()));
        Button doneButton = view.findViewById(R.id.doneButton);
        doneButton.setOnClickListener(new DoneButtonClickListener());
        lastclicked = originalButton;
        tintButton(ContextCompat.getColor(getActivity(), R.color.blue), originalButton);
    }

    private Bitmap getBitmap() {
        final Uri uri = getArguments().getParcelable(BUNDLE_EXTRA_KEY_SCANNED_RESULT);
        try {
            assert uri != null;
            original = check4AvoidTooLargeOpenGLError(UtilsKt.getBitmap(getActivity(), uri));
            new File(uri.getPath()).deleteOnExit();
            return original;
        }
        catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    private Bitmap check4AvoidTooLargeOpenGLError(final Bitmap bitmap) {
        final int originalHeight = bitmap.getHeight();
        final int originalWidth = bitmap.getWidth();
        if (originalHeight <= 1500 && originalWidth <= 1500) {
            return bitmap;
        }
        int finalHeight;
        int finalWidth;
        if (originalHeight > originalWidth) {
            //Height is more bigger than width, scaling by height...
            finalHeight = 1500;
            finalWidth = (1500 * originalWidth) / originalHeight;
        }
        else {
            //Scaling by width...
            finalWidth = 1500;
            finalHeight = (1500 * originalHeight) / originalWidth;
        }
        Log.d(this.getClass().getSimpleName(), "Bitmap rescaled for avoid OpenGL too large error --> final size:{width: " + finalWidth + ", height: " + finalHeight + "}");
        return Bitmap.createScaledBitmap(bitmap, finalWidth, finalHeight, true);
    }

    private class DoneButtonClickListener implements View.OnClickListener {
        @Override
        public void onClick(View v) {
            tintButton(ContextCompat.getColor(getActivity(), android.R.color.white), lastclicked);
            lastclicked = (Button) v;
            tintButton(ContextCompat.getColor(getActivity(), R.color.blue), (Button) v);
            showProgressDialog(getResources().getString(R.string.loading));
            AsyncTask.execute(new Runnable() {
                @Override
                public void run() {
                    try {

                        //Delete cropped image
                        boolean wasDeleted = new File(((Uri) getArguments().getParcelable(BUNDLE_EXTRA_KEY_SCANNED_RESULT)).getPath()).delete();

                        //Save scanned image
                        final String resultImagePath = UtilsKt.saveImage(
                                getArguments().getString(BUNDLE_EXTRA_KEY_IMAGES_PATH),
                                getArguments().getString(BUNDLE_EXTRA_KEY_IMAGE_NAME),
                                transformed != null ? transformed : original
                        );

                        getActivity().runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                final Intent intentResult = new Intent();
                                intentResult.putExtra(ScanActivity.BUNDLE_RESULT_KEY_SCANNED_IMAGE_PATH, resultImagePath);
                                getActivity().setResult(Activity.RESULT_OK, intentResult);
                                original.recycle();
                                System.gc();
                                dismissDialog();
                                getActivity().finish();
                            }
                        });
                    }
                    catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            });
        }
    }

    private class BWButtonClickListener implements View.OnClickListener {
        @Override
        public void onClick(final View v) {
            tintButton(ContextCompat.getColor(getActivity(), android.R.color.white), lastclicked);
            lastclicked = (Button) v;
            tintButton(ContextCompat.getColor(getActivity(), R.color.blue), (Button) v);
            showProgressDialog(getResources().getString(R.string.applying_filter));
            AsyncTask.execute(new Runnable() {
                @Override
                public void run() {
                    try {
                        transformed = ((ScanActivity) getActivity()).getBWBitmap(original);
                    }
                    catch (final OutOfMemoryError e) {
                        getActivity().runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                transformed = original;
                                scannedImageView.setImageBitmap(original);
                                e.printStackTrace();
                                dismissDialog();
                                onClick(v);
                            }
                        });
                    }
                    getActivity().runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            scannedImageView.setImageBitmap(transformed);
                            dismissDialog();
                        }
                    });
                }
            });
        }
    }

    private class MagicColorButtonClickListener implements View.OnClickListener {
        @Override
        public void onClick(final View v) {
            tintButton(ContextCompat.getColor(getActivity(), android.R.color.white), lastclicked);
            lastclicked = (Button) v;
            tintButton(ContextCompat.getColor(getActivity(), R.color.blue), (Button) v);
            showProgressDialog(getResources().getString(R.string.applying_filter));
            AsyncTask.execute(new Runnable() {
                @Override
                public void run() {
                    try {
                        transformed = ((ScanActivity) getActivity()).getMagicColorBitmap(original);
                    }
                    catch (final OutOfMemoryError e) {
                        getActivity().runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                transformed = original;
                                scannedImageView.setImageBitmap(original);
                                e.printStackTrace();
                                dismissDialog();
                                onClick(v);
                            }
                        });
                    }
                    getActivity().runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            scannedImageView.setImageBitmap(transformed);
                            dismissDialog();
                        }
                    });
                }
            });
        }
    }

    private class OriginalButtonClickListener implements View.OnClickListener {
        @Override
        public void onClick(View v) {
            tintButton(ContextCompat.getColor(getActivity(), android.R.color.white), lastclicked);
            lastclicked = (Button) v;
            tintButton(ContextCompat.getColor(getActivity(), R.color.blue), (Button) v);
            try {
                showProgressDialog(getResources().getString(R.string.applying_filter));
                transformed = original;
                scannedImageView.setImageBitmap(original);
                dismissDialog();
            }
            catch (OutOfMemoryError e) {
                e.printStackTrace();
                dismissDialog();
            }
        }
    }

    private class GrayButtonClickListener implements View.OnClickListener {
        @Override
        public void onClick(final View v) {
            tintButton(ContextCompat.getColor(getActivity(), android.R.color.white), lastclicked);
            lastclicked = (Button) v;
            tintButton(ContextCompat.getColor(getActivity(), R.color.blue), (Button) v);
            showProgressDialog(getResources().getString(R.string.applying_filter));
            AsyncTask.execute(new Runnable() {
                @Override
                public void run() {
                    try {
                        transformed = ((ScanActivity) getActivity()).getGrayBitmap(original);
                    }
                    catch (final OutOfMemoryError e) {
                        getActivity().runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                transformed = original;
                                scannedImageView.setImageBitmap(original);
                                e.printStackTrace();
                                dismissDialog();
                                onClick(v);
                            }
                        });
                    }
                    getActivity().runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            scannedImageView.setImageBitmap(transformed);
                            dismissDialog();
                        }
                    });
                }
            });
        }
    }

    protected synchronized void showProgressDialog(String message) {
        if (progressDialogFragment != null && progressDialogFragment.isVisible()) {
            // Before creating another loading dialog, close all opened loading dialogs (if any)
            progressDialogFragment.dismissAllowingStateLoss();
        }
        progressDialogFragment = null;
        progressDialogFragment = new ProgressDialogFragment(message);
        FragmentManager fm = getFragmentManager();
        progressDialogFragment.show(fm, ProgressDialogFragment.class.toString());
    }

    protected synchronized void dismissDialog() {
        progressDialogFragment.dismissAllowingStateLoss();
    }

    private void tintButton(final int colorId, final Button target) {
        target.setTextColor(colorId);
        Drawable[] drawables = target.getCompoundDrawablesRelative();
        for (Drawable drawable : drawables) {
            if (drawable != null) {
                drawable.setColorFilter(colorId, PorterDuff.Mode.SRC_ATOP);
            }
        }
    }
}