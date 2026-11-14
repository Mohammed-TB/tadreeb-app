import { NextFunction, Request, Response } from "express";

const createCourse = (req: Request, res: Response) => {
  const title = req.body.title;
  const price = req.body.price;

  console.log(title);
  console.log(price);
};

// Flutter Send Http Request to Node.js Backend

// Express Controller Read Request and determine the type of request (GET, POST, PUT, DELETE) ;

// Flutter App Deilvering Response and Viewing app;

// Request :  هو الطلب الذي يرسله العميل ال backend

// POST: Createe
// PUT: Update
// GET: Read
// DELETE: Delete
// PATCH: Update Partial

// Example: الطالب يريد التسجيل في الدورة

// POST /api/courses
// Data = > {
//   title: "Introduction to Programming",
//   price: 100
// }

// Controller : نستطيع قراءة البيانات من req.body و req.params و req.query , req.headers

// Exmple: req.body
/*
const createCourse = (req:Request,res:Response)=>{
const title = req.body.title;
const price = req.body.price;


}


Example : req.params

GET /api/courses/12345

routes: router.get("/:id", courseController.getCourse);
const getCourse = (req: Request, res: Response) => {
  const courseId = req.params.id;

  console.log(courseId);
};

// Response : هو الرد الذي يرسله ال backend للعميل

اهم الاكواد التي يمكن استخدامها في ال response :
- res.status(code): تحدد كود الحالة للرد
- res.json(data): ترسل بيانات JSON كرد

res.status(200);
200: The request has succeeded.
201: تم إنشاء العنصر بنجاح.
400: Bad Request: الطلب غير صالح.
401: المستخدم غير مسجل الدخول
403: Unauthorized: غير مصرح.
404: Not Found: العنصر غير موجود.
500: Internal Server Error: خطأ في الخادم.

*/

// const getStudent = (req: Request, res: Response) => {
//   const studentID = req.params.id;
//   if (!studentID) {
//     return res.status(400).json({
//       success: false,
//       message: "بيانات الطالب غير موجودة",
//     });
//   }
//   res.status(200).json({
//     success: true,
//     message: "student fetched sccessfully",
//     data: {
//       id: studentID,
//       name: "Mohammed Talib",
//       price: 5000,
//     },
//   });
// };

// const registerStudent = (req: Request, res: Response) => {
//   const name = req.body.name;
//   const email = req.body.email;
//   const phone = req.body.phone;

//   if (!name || !email) {
//     return res.status(400).json({
//       success: false,
//       message: "Student Not Registered Successfully",
//     });
//   }

//   return res.status(201).json({
//     success: true,
//     message: "Student Regustered Successfully",
//     data: {
//       name,
//       email,
//       phone
//     },
//   });
// };

// const filterCourses = (req:Request,res:Response)=>{
//     const category = req.query.category;
//     const maxPrice = req.query.maxPrice ?  Number(req.query.maxPrice): 100000 ;

//     if(!category || typeof category !== "string"){
//         return res.status(400).json({
//             success:false,
//             message:"Category is required"
//         })
//     }
//     if(maxPrice <= 0){
//         return res.status(400).json({
//             success:false,
//             message:"Max Price must be greater than 0"
//         })
//     }
//     if(!Number.isFinite(maxPrice)){
//         return res.status(400).json({
//             success:false,
//             message:"Max Price must be a number"
//         })
//     }

//     return res.status(200).json({
//         success:true,
//         message :"Courses filtered successfully",
//         data:{
//             category,
//             maxPrice
//         }
//     })
// }

// const filterCourses = async (
//   req: Request,
//   res: Response,
//   next: NextFunction
// ) => {
//   try {
//     const category = req.query.category;
//     const maxPrice = req.query.maxPrice
//       ? Number(req.query.maxPrice)
//       : 100000;

//     // التحقق من المدخلات.
//     if (typeof category !== "string" || !category.trim()) {
//       return res.status(400).json({
//         success: false,
//         message: "Category is required",
//       });
//     }

//     if (!Number.isFinite(maxPrice) || maxPrice <= 0) {
//       return res.status(400).json({
//         success: false,
//         message: "Invalid max price",
//       });
//     }

//     // استدعاء Service.
//     const courses = await filterCoursesService.filterCoursesService({
//       category,
//       maxPrice,
//     });

//     return res.status(200).json({
//       success: true,
//       message: "Courses filtered successfully",
//       data: courses,
//     });
//   } catch (error) {
//     next(error);
//   }
// };

// Controller

// import bookingService from "./booking.service";

// const createBooking = async (
//   req: Request,
//   res: Response,
//   next: NextFunction
// ) => {
//   try {
//     // استقبال بيانات العميل.
//     const {
//       customerName,
//       carModel,
//       serviceType,
//       bookingDate,
//     } = req.body;

//     // التحقق من البيانات المطلوبة.
//     if (!customerName || !carModel || !serviceType || !bookingDate) {
//       return res.status(400).json({
//         success: false,
//         message: "All booking fields are required",
//       });
//     }

//     // إرسال البيانات إلى Service.
//     const booking = await bookingService.createBooking({
//       customerName,
//       carModel,
//       serviceType,
//       bookingDate,
//     });

//     // إعادة نتيجة الحجز.
//     return res.status(201).json({
//       success: true,
//       message: "Booking created successfully",
//       data: booking,
//     });

//   } catch (error) {
//     next(error);
//   }
// };

// export default { createBooking };

// const deleteBooking = async (
//   req: Request,
//   res: Response,
//   next: NextFunction,
// ) => {
//   const bookingID = req.params.id;
//   try {
//     if (typeof bookingID !== "string" || !bookingID) {
//       return res.status(400).json({
//         success: false,
//         message: "Booking is Not Found",
//       });
//     }
//     const booking = await bookingService.deleteBooking(bookingID);
//     return res.status(200).json({
//       success: true,
//       message: "Booking deleted successfully",
//       data: booking,
//     });
//   } catch (error) {
//     next(error);
//   }
// };

// const updateBooking = async(req:Request,res:Response,next:NextFunction)=>{
//     const bookingID = req.params.id;
//     const bookingDate = req.body.bookingDate;
//     try{

//             if(typeof bookingID !== "string" || !bookingID){
//         return res.status(400).json({
//             success: false,
//             message:'Booking Not Found',
//         })
//     }
//     if(typeof bookingDate !== 'string' || !bookingDate){
//               return  res.status(400).json({
//             success: false,
//             message:'Booking Date is Required',
//         })
//     }

//     const booking = await  updateBookingService.updateBooking(bookingID,{data:bookingDate});
//     return res.status(200).json({
//         success:true,
//         message:'update Booking is Successfully',
//         data:booking
//     })

//     }catch(error){
//         next(error);
//     }

// }


// class MaintenanceService{
 


//   async createMaintenance()
// }