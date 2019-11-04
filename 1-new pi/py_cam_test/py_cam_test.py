import cv2

cap = cv2.VideoCapture(0)

while(cap.isOpened()):
	ret,frame = cap.read()
	cv2.imshow('capture', frame)
	key = cv2.waitKey(1)
	if key & 0x00FF == ord('q'):
		break
	
cap.release()
cv2.destroyAllWindows()
