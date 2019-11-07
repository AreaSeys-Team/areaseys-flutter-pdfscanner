package com.areaseys.pdfscanner.pdfscanner;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.Fragment;
import android.app.FragmentManager;
import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.graphics.PointF;
import android.graphics.drawable.BitmapDrawable;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.util.SparseArray;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * Created by jhansi on 29/03/15.
 * modified by Santi Hoyos on 22/10/19
 */
public class ScanFragment extends Fragment {

    public static final String BUNDLE_EXTRA_KEY_SELECTED_BITMAP = "selectedBitmap";
    public static final String BUNDLE_EXTRA_KEY_IMAGES_PATH = "scannedImagesPath";
    public static final String BUNDLE_EXTRA_KEY_IMAGE_NAME = "scannedImageName";

    private ImageView sourceImageView;
    private FrameLayout sourceFrame;
    private PolygonView polygonView;
    private View view;
    private ProgressDialogFragment progressDialogFragment;
    private IScanner scanner;
    private Bitmap original;

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);
        if (!(activity instanceof IScanner)) {
            throw new ClassCastException("Activity must implement IScanner");
        }
        this.scanner = (IScanner) activity;
    }

    @Override
    @SuppressLint("InflateParams")
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        view = inflater.inflate(R.layout.scan_fragment_layout, null);
        init();
        return view;
    }

    private void init() {
        sourceImageView = view.findViewById(R.id.sourceImageView);
        Button scanButton = view.findViewById(R.id.mButtonCut);
        scanButton.setOnClickListener(new ScanButtonClickListener());
        sourceFrame = view.findViewById(R.id.sourceFrame);
        polygonView = view.findViewById(R.id.polygonView);
        sourceFrame.post(new Runnable() {
            @Override
            public void run() {
                original = getBitmap();
                if (original != null) {
                    setBitmap(original);
                }
            }
        });
        view.findViewById(R.id.mButtonRotateLeft).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                AsyncTask.execute(new Runnable() {
                    @Override
                    public void run() {
                        rotateImage(-90);
                    }
                });
            }
        });
        view.findViewById(R.id.mButtonRotateRight).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                AsyncTask.execute(new Runnable() {
                    @Override
                    public void run() {
                        rotateImage(+90);
                    }
                });
            }
        });
        view.findViewById(R.id.mButtonCancel).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                original.recycle();
                getActivity().finish();
            }
        });
    }

    private Bitmap getBitmap() {
        final Uri uri = getArguments().getParcelable(BUNDLE_EXTRA_KEY_SELECTED_BITMAP);
        assert uri != null;
        final Bitmap bitmap = UtilsKt.getBitmap(uri, sourceFrame.getHeight(), sourceFrame.getWidth());
        new File(uri.getPath()).deleteOnExit();
        return bitmap;
    }

    private void setBitmap(Bitmap original) {
        sourceImageView.setImageBitmap(original);
        final Bitmap tempBitmap = ((BitmapDrawable) sourceImageView.getDrawable()).getBitmap();
        final SparseArray<PointF> pointFs = getEdgePoints(tempBitmap);
        polygonView.setPoints(pointFs);
        polygonView.setVisibility(View.VISIBLE);
        final int padding = (int) getResources().getDimension(R.dimen.scanPadding);
        final FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(tempBitmap.getWidth() + 2 * padding, tempBitmap.getHeight() + 2 * padding);
        layoutParams.gravity = Gravity.CENTER;
        polygonView.setLayoutParams(layoutParams);
    }

    private SparseArray<PointF> getEdgePoints(Bitmap tempBitmap) {
        List<PointF> pointFs = getContourEdgePoints(tempBitmap);
        return orderedValidEdgePoints(tempBitmap, pointFs);
    }

    private List<PointF> getContourEdgePoints(Bitmap tempBitmap) {
        float[] points = ((ScanActivity) getActivity()).getPoints(tempBitmap);
        float x1 = points[0];
        float x2 = points[1];
        float x3 = points[2];
        float x4 = points[3];

        float y1 = points[4];
        float y2 = points[5];
        float y3 = points[6];
        float y4 = points[7];

        List<PointF> pointFs = new ArrayList<>();
        pointFs.add(new PointF(x1, y1));
        pointFs.add(new PointF(x2, y2));
        pointFs.add(new PointF(x3, y3));
        pointFs.add(new PointF(x4, y4));
        return pointFs;
    }

    private SparseArray<PointF> getOutlinePoints(Bitmap tempBitmap) {
        SparseArray<PointF> outlinePoints = new SparseArray<>();
        outlinePoints.put(0, new PointF(0, 0));
        outlinePoints.put(1, new PointF(tempBitmap.getWidth(), 0));
        outlinePoints.put(2, new PointF(0, tempBitmap.getHeight()));
        outlinePoints.put(3, new PointF(tempBitmap.getWidth(), tempBitmap.getHeight()));
        return outlinePoints;
    }

    private SparseArray<PointF> orderedValidEdgePoints(Bitmap tempBitmap, List<PointF> pointFs) {
        SparseArray<PointF> orderedPoints = polygonView.getOrderedPoints(pointFs);
        if (!polygonView.isValidShape(orderedPoints)) {
            orderedPoints = getOutlinePoints(tempBitmap);
        }
        return orderedPoints;
    }

    private class ScanButtonClickListener implements View.OnClickListener {
        @Override
        public void onClick(View v) {
            SparseArray<PointF> points = polygonView.getPoints();
            if (isScanPointsValid(points)) {
                new ScanAsyncTask(points).execute();
            }
            else {
                showErrorDialog();
            }
        }
    }

    private void showErrorDialog() {
        SingleButtonDialogFragment fragment = new SingleButtonDialogFragment(R.string.ok, getString(R.string.cantCrop), "Error", true);
        FragmentManager fm = getActivity().getFragmentManager();
        fragment.show(fm, SingleButtonDialogFragment.class.toString());
    }

    private boolean isScanPointsValid(SparseArray<PointF> points) {
        return points.size() == 4;
    }

    private Bitmap getScannedBitmap(Bitmap original, SparseArray<PointF> points) {
        float xRatio = (float) original.getWidth() / sourceImageView.getWidth();
        float yRatio = (float) original.getHeight() / sourceImageView.getHeight();

        float x1 = (points.get(0).x) * xRatio;
        float x2 = (points.get(1).x) * xRatio;
        float x3 = (points.get(2).x) * xRatio;
        float x4 = (points.get(3).x) * xRatio;
        float y1 = (points.get(0).y) * yRatio;
        float y2 = (points.get(1).y) * yRatio;
        float y3 = (points.get(2).y) * yRatio;
        float y4 = (points.get(3).y) * yRatio;
        Log.d("", "Points(" + x1 + "," + y1 + ")(" + x2 + "," + y2 + ")(" + x3 + "," + y3 + ")(" + x4 + "," + y4 + ")");
        return ((ScanActivity) getActivity()).getScannedBitmap(original, x1, y1, x2, y2, x3, y3, x4, y4);
    }

    @SuppressLint("StaticFieldLeak")
    private class ScanAsyncTask extends AsyncTask<Void, Void, Bitmap> {

        private SparseArray<PointF> points;

        ScanAsyncTask(SparseArray<PointF> points) {
            this.points = points;
        }

        @Override
        protected void onPreExecute() {
            super.onPreExecute();
            showProgressDialog(getString(R.string.scanning));
        }

        @Override
        protected Bitmap doInBackground(Void... params) {
            Bitmap bitmap = getScannedBitmap(original, points);
            final Uri uri = Uri.fromFile(new File(UtilsKt.saveImage(
                    Objects.requireNonNull(getArguments().getString(BUNDLE_EXTRA_KEY_IMAGES_PATH)),
                    getArguments().getString(BUNDLE_EXTRA_KEY_IMAGE_NAME) + "_scanned",
                    bitmap
            )));
            scanner.onScanFinish(uri);
            return bitmap;
        }

        @Override
        protected void onPostExecute(Bitmap bitmap) {
            super.onPostExecute(bitmap);
            bitmap.recycle();
            dismissDialog();
        }
    }

    protected void showProgressDialog(String message) {
        progressDialogFragment = new ProgressDialogFragment(message);
        FragmentManager fm = getFragmentManager();
        progressDialogFragment.show(fm, ProgressDialogFragment.class.toString());
    }

    protected void dismissDialog() {
        progressDialogFragment.dismissAllowingStateLoss();
    }

    /**
     * Rotate original bitmap.
     *
     * @param degrees rotation as degrees
     */
    private void rotateImage(float degrees) {
        showProgressDialog("Rotating " + degrees + "º...");
        final Matrix matrix = new Matrix();
        matrix.postRotate(degrees);
        final Bitmap newBitmap = Bitmap.createBitmap(original, 0, 0, original.getWidth(), original.getHeight(), matrix, true);
        getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                setBitmap(newBitmap);
                original.recycle();
                original = newBitmap;
                dismissDialog();
            }
        });
    }
}