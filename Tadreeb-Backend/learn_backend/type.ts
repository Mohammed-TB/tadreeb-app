import { MaintenanceStatus } from "./model";


export interface CreateMaintenanceInput {
  customerName: string;
  carModel: string;
  serviceType: string;
  bookingDate: string;
}

export interface UpdateMaintenanceStatusInput {
  status: MaintenanceStatus;
}
