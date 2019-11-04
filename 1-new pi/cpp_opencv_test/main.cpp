#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>

#include <vector>
#include <cstdio>

using namespace cv;
using namespace std;
int main (int argc, char **argv)
{
	Mat image, image_gray;
	image = imread(argv[1], CV_LOAD_IMAGE_COLOR );
	vector<int> compression_params;

	if (argc != 2 || !image.data) {
		fprintf(stdout, "No image data\n");
		return -1;
	}

	compression_params.push_back(CV_IMWRITE_JPEG_QUALITY);
	compression_params.push_back(95);

	cvtColor(image, image_gray, CV_RGB2GRAY);
//	namedWindow("image", CV_WINDOW_AUTOSIZE);
//	namedWindow("image gray", CV_WINDOW_AUTOSIZE);

//	imshow("image", image);
//	imshow("image gray", image_gray);

	try
	{
		imwrite("out.jpg", image_gray, compression_params);
	}
	catch (runtime_error& ex)
	{
		fprintf(stderr, "Exception converting image to JPG format: %s\n", ex.what());
		return 1;
	}

	fprintf(stdout, "Saved JPG file gray\n");

	waitKey(0);
	return 0;
}
